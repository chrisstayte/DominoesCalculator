import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// Fixed-square letterboxing used by the exported detector, in source pixels.
class DominoLetterbox {
  final int width;
  final int height;
  final int size;
  late final double scale = math.min(size / width, size / height);
  late final int resizedWidth = roundEven(width * scale);
  late final int resizedHeight = roundEven(height * scale);
  late final int left = ((size - resizedWidth) / 2 - 0.1).round();
  late final int top = ((size - resizedHeight) / 2 - 0.1).round();

  DominoLetterbox(this.width, this.height, {this.size = 640});

  Offset toSource(Offset point) =>
      Offset((point.dx - left) / scale, (point.dy - top) / scale);
}

int roundEven(double value) {
  final floor = value.floor();
  final remainder = value - floor;
  if (remainder == 0.5) return floor.isEven ? floor : floor + 1;
  return value.round();
}

class DominoBox {
  final double x, y, width, height, angle, confidence;
  const DominoBox(
    this.x,
    this.y,
    this.width,
    this.height,
    this.angle,
    this.confidence,
  );

  List<Offset> get corners {
    final a = Offset(width / 2 * math.cos(angle), width / 2 * math.sin(angle));
    final b = Offset(
      -height / 2 * math.sin(angle),
      height / 2 * math.cos(angle),
    );
    final center = Offset(x, y);
    return [center + a + b, center + a - b, center - a - b, center - a + b];
  }
}

/// Decode the actual [1, 6, 8400] float output: normalized xywh, score, radians.
/// Rotated Fast-NMS compares each candidate to every higher-scoring candidate,
/// including candidates which are themselves suppressed.
List<DominoBox> decodeDominoBoxes(
  Float32List output, {
  int candidates = 8400,
  int imageSize = 640,
  double confidence = 0.25,
  double iouThreshold = 0.7,
  int maxDetections = 300,
}) {
  if (output.length != candidates * 6) {
    throw ArgumentError('Unexpected domino detector output shape.');
  }
  final boxes = <DominoBox>[];
  for (var i = 0; i < candidates; i++) {
    final score = output[candidates * 4 + i];
    if (!score.isFinite || score <= confidence) continue;
    final values = [for (var c = 0; c < 6; c++) output[candidates * c + i]];
    if (values.any((v) => !v.isFinite) || values[2] <= 0 || values[3] <= 0) {
      continue;
    }
    boxes.add(
      DominoBox(
        values[0] * imageSize,
        values[1] * imageSize,
        values[2] * imageSize,
        values[3] * imageSize,
        values[5],
        score,
      ),
    );
  }
  boxes.sort((a, b) => b.confidence.compareTo(a.confidence));
  final kept = <DominoBox>[];
  for (var i = 0; i < boxes.length && kept.length < maxDetections; i++) {
    var suppressed = false;
    for (var j = 0; j < i; j++) {
      if (probabilisticIou(boxes[j], boxes[i]) >= iouThreshold) {
        suppressed = true;
        break;
      }
    }
    if (!suppressed) kept.add(boxes[i]);
  }
  return kept;
}

/// Gaussian rectangle overlap used by Ultralytics' rotated Fast-NMS.
double probabilisticIou(DominoBox first, DominoBox second) {
  List<double> covariance(DominoBox box) {
    final a = box.width * box.width / 12;
    final b = box.height * box.height / 12;
    final cos = math.cos(box.angle), sin = math.sin(box.angle);
    return [
      a * cos * cos + b * sin * sin,
      a * sin * sin + b * cos * cos,
      (a - b) * cos * sin,
    ];
  }

  const epsilon = 1e-7;
  final u = covariance(first), v = covariance(second);
  final a = u[0] + v[0], b = u[1] + v[1], c = u[2] + v[2];
  final determinant = a * b - c * c;
  final dx = first.x - second.x, dy = first.y - second.y;
  final t1 = (a * dy * dy + b * dx * dx) / (determinant + epsilon) * 0.25;
  final t2 = c * -dx * dy / (determinant + epsilon) * 0.5;
  final area = math.sqrt(
    math.max(0, u[0] * u[1] - u[2] * u[2]) *
        math.max(0, v[0] * v[1] - v[2] * v[2]),
  );
  final t3 = math.log(determinant / (4 * area + epsilon) + epsilon) * 0.5;
  final distance = (t1 + t2 + t3).clamp(epsilon, 100.0);
  return 1 - math.sqrt(1 - math.exp(-distance) + epsilon);
}

double signedPolygonArea(List<Offset> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i], b = points[(i + 1) % points.length];
    area += a.dx * b.dy - a.dy * b.dx;
  }
  return area / 2;
}

double polygonIou(List<Offset> first, List<Offset> second) {
  var subject = List<Offset>.of(first);
  final clip = signedPolygonArea(second) < 0
      ? second.reversed.toList()
      : second;
  double cross(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;
  for (var i = 0; i < clip.length; i++) {
    final a = clip[i], edge = clip[(i + 1) % clip.length] - a;
    final input = subject;
    subject = [];
    if (input.isEmpty) return 0;
    var previous = input.last;
    var previousDistance = cross(edge, previous - a);
    for (final current in input) {
      final distance = cross(edge, current - a);
      if ((distance >= 0) != (previousDistance >= 0)) {
        final fraction = previousDistance / (previousDistance - distance);
        subject.add(previous + (current - previous) * fraction);
      }
      if (distance >= 0) subject.add(current);
      previous = current;
      previousDistance = distance;
    }
  }
  final intersection = signedPolygonArea(subject).abs();
  final union =
      signedPolygonArea(first).abs() +
      signedPolygonArea(second).abs() -
      intersection;
  return union > 0 ? intersection / union : 0;
}

/// Positive image-space winding, then the longest edge first, matching notebook 2.
List<Offset> canonicalTileCorners(List<Offset> corners) {
  // Notebook geometry uses NumPy float32, including tie-breaking between
  // opposite long edges. Preserve that convention to avoid a 180-degree crop.
  double f32(double value) => Float32List.fromList([value])[0];
  corners = [for (final p in corners) Offset(f32(p.dx), f32(p.dy))];
  if (corners.length != 4 ||
      corners.any((p) => !p.dx.isFinite || !p.dy.isFinite) ||
      signedPolygonArea(corners).abs() < 4) {
    throw ArgumentError('Unreadable tile geometry.');
  }
  final points = signedPolygonArea(corners) < 0
      ? corners.reversed.toList()
      : List<Offset>.of(corners);
  var start = 0, longest = -1.0;
  for (var i = 0; i < 4; i++) {
    final delta = points[(i + 1) % 4] - points[i];
    final dx = f32(delta.dx), dy = f32(delta.dy);
    final length = f32(math.sqrt(f32(f32(dx * dx) + f32(dy * dy))));
    if (length > longest) {
      longest = length;
      start = i;
    }
  }
  return [for (var i = 0; i < 4; i++) points[(i + start) % 4]];
}

/// Inverse homography: destination 256x128 pixels -> source quadrilateral.
List<double> tileHomography(List<Offset> corners) {
  final points = canonicalTileCorners(corners);
  const target = [
    Offset(0, 0),
    Offset(255, 0),
    Offset(255, 127),
    Offset(0, 127),
  ];
  final matrix = <List<double>>[];
  for (var i = 0; i < 4; i++) {
    final u = target[i].dx,
        v = target[i].dy,
        x = points[i].dx,
        y = points[i].dy;
    matrix.add([u, v, 1, 0, 0, 0, -x * u, -x * v, x]);
    matrix.add([0, 0, 0, u, v, 1, -y * u, -y * v, y]);
  }
  for (var column = 0; column < 8; column++) {
    var pivot = column;
    for (var row = column + 1; row < 8; row++) {
      if (matrix[row][column].abs() > matrix[pivot][column].abs()) pivot = row;
    }
    if (matrix[pivot][column].abs() < 1e-10) {
      throw ArgumentError('Degenerate tile.');
    }
    final temporary = matrix[column];
    matrix[column] = matrix[pivot];
    matrix[pivot] = temporary;
    final scale = matrix[column][column];
    for (var j = column; j < 9; j++) {
      matrix[column][j] /= scale;
    }
    for (var row = 0; row < 8; row++) {
      if (row == column) continue;
      final factor = matrix[row][column];
      for (var j = column; j < 9; j++) {
        matrix[row][j] -= factor * matrix[column][j];
      }
    }
  }
  return [for (var i = 0; i < 8; i++) matrix[i][8]];
}
