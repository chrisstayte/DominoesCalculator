"""Standalone pip-label review controls, embedded into notebook 3 by the builder."""
import base64
import csv
import hashlib
import io
import json
import shutil
from datetime import datetime, timezone
from html import escape
from pathlib import Path
from uuid import uuid4

from PIL import Image


class PipLabelReview:
    def __init__(self, crops):
        self.crops = Path(crops).resolve()
        self.labels_path = self.crops / "pip_labels.csv"
        self.progress_path = self.crops / "pip_label_review.json"
        self.backup_path = None
        self.tiles = self.read_csv(self.crops / "tiles.csv")
        self.ids = [tile["tile_id"] for tile in self.tiles]
        if not self.tiles or len(set(self.ids)) != len(self.ids):
            raise ValueError("The crop manifest must contain unique tile IDs.")
        for tile in self.tiles:
            for side in ("a", "b"):
                path = Path(tile[f"{side}_path"])
                if path.is_absolute() or ".." in path.parts:
                    raise ValueError("A half-image is outside the crop directory.")
        self.metadata = json.loads((self.crops / "metadata.json").read_text())
        self.manifest_key = self.token({"metadata": self.metadata, "tiles": self.tiles})
        self.flags = {}
        flags_path = self.crops / "pip_review_flags.json"
        if flags_path.exists():
            flags = json.loads(flags_path.read_text())
            if any(flags.get(key) != self.metadata.get(key) for key in ("dataset_fingerprint", "crop_version")):
                raise ValueError("Review flags belong to different crops. Use the matching flags file.")
            for flag in flags.get("flags", []):
                if flag["tile_id"] not in self.ids or flag["side"] not in ("a", "b"):
                    raise ValueError("Review flags contain an unknown tile or half.")
                self.flags.setdefault(flag["tile_id"], []).append(flag)
        self.default_mode = "flagged" if self.flags else "all"
        self.load_labels()
        self.load_progress()

    @staticmethod
    def read_csv(path):
        with Path(path).open(newline="") as source:
            return list(csv.DictReader(source))

    @staticmethod
    def token(value):
        return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()

    @staticmethod
    def atomic_json(path, value):
        temporary = path.with_suffix(path.suffix + ".tmp")
        temporary.write_text(json.dumps(value, indent=2) + "\n")
        temporary.replace(path)

    def load_labels(self):
        rows = self.read_csv(self.labels_path)
        if len(rows) != len(self.ids) or {row["tile_id"] for row in rows} != set(self.ids):
            raise ValueError("Saved labels do not match the crop manifest.")
        for row in rows:
            if row["status"] not in {"pending", "labeled", "rejected"}:
                raise ValueError("A saved label has an invalid status.")
            if row["status"] == "labeled" and any(row[side] not in {str(i) for i in range(16)} for side in ("a", "b")):
                raise ValueError("Saved pip values must be integers from 0 to 15.")
        return rows, {row["tile_id"]: row for row in rows}

    def load_progress(self):
        if not self.progress_path.exists():
            return {"manifest_key": self.manifest_key, "reviewed": {}}
        progress = json.loads(self.progress_path.read_text())
        if progress.get("manifest_key") != self.manifest_key:
            raise ValueError("Review progress belongs to a different crop manifest.")
        if not isinstance(progress.get("reviewed"), dict):
            raise ValueError("Review progress is invalid.")
        return progress

    def queue(self, mode, labels, progress):
        if mode not in {"flagged", "all", "unreviewed"}:
            raise ValueError("Choose Flagged, All tiles, or Unreviewed.")
        return [i + 1 for i, tile_id in enumerate(self.ids)
                if (mode != "flagged" or tile_id in self.flags)
                and (mode != "unreviewed" or progress["reviewed"].get(tile_id) != self.token(labels[tile_id]))]

    def state(self, number=None, mode=None, message=""):
        mode = mode or self.default_mode
        _, labels = self.load_labels()
        progress = self.load_progress()
        queue = self.queue(mode, labels, progress)
        unchecked = [n for n in queue if progress["reviewed"].get(self.ids[n - 1]) != self.token(labels[self.ids[n - 1]])]
        if number is None:
            number = (unchecked or queue or [1])[0]
        if type(number) is not int or not 1 <= number <= len(self.tiles):
            raise ValueError(f"Choose a tile between 1 and {len(self.tiles)}.")
        tile = self.tiles[number - 1]
        row = labels[tile["tile_id"]]
        images = {}
        for side in ("a", "b"):
            path = (self.crops / tile[f"{side}_path"]).resolve()
            if not path.is_relative_to(self.crops):
                raise ValueError("A half-image is outside the crop directory.")
            with Image.open(path) as original:
                buffer = io.BytesIO()
                original.convert("RGB").save(buffer, format="PNG")
                images[side] = base64.b64encode(buffer.getvalue()).decode("ascii")
        reviewed = sum(progress["reviewed"].get(tile_id) == self.token(labels[tile_id]) for tile_id in self.ids)
        return {"number": number, "total": len(self.tiles), "tile_id": tile["tile_id"], "image": tile["image"],
                "a": row["a"], "b": row["b"], "status": row["status"], "token": self.token(row), "images": images,
                "mode": mode, "flag_count": len(self.flags), "queue_total": len(queue), "remaining": len(unchecked),
                "reviewed": reviewed, "flags": self.flags.get(tile["tile_id"], []), "message": message,
                "complete": not unchecked, "is_reviewed": progress["reviewed"].get(tile["tile_id"]) == self.token(row)}

    def act(self, action, number, a="", b="", expected="", mode="all"):
        if type(number) is not int or not 1 <= number <= len(self.tiles):
            raise ValueError(f"Choose a tile between 1 and {len(self.tiles)}.")
        rows, labels = self.load_labels()
        progress = self.load_progress()
        queue = self.queue(mode, labels, progress)
        row = labels[self.ids[number - 1]]
        message = ""
        if action in {"save", "reject"}:
            if expected != self.token(row):
                raise ValueError("This tile changed in another session. Click Reload tile before saving.")
            if action == "save" and (a not in {str(i) for i in range(16)} or b not in {str(i) for i in range(16)}):
                raise ValueError("Choose a value from 0 to 15 for both halves.")
            updated = dict(row, a=a if action == "save" else "", b=b if action == "save" else "",
                           status="labeled" if action == "save" else "rejected")
            if updated != row:
                if self.backup_path is None:
                    backup_dir = self.crops / "label_review_backups"
                    backup_dir.mkdir(exist_ok=True)
                    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")
                    self.backup_path = backup_dir / f"pip_labels-{stamp}-{uuid4().hex[:8]}.csv"
                    shutil.copy2(self.labels_path, self.backup_path)
                shutil.copy2(self.labels_path, self.labels_path.with_suffix(".previous.csv"))
                row.update(updated)
                temporary = self.labels_path.with_suffix(".csv.tmp")
                with temporary.open("w", newline="") as target:
                    writer = csv.DictWriter(target, fieldnames=["tile_id", "a", "b", "status"])
                    writer.writeheader()
                    writer.writerows(rows)
                temporary.replace(self.labels_path)
            progress["reviewed"][row["tile_id"]] = self.token(updated)
            self.atomic_json(self.progress_path, progress)
            message = f"Saved tile {number} to Drive." if self.crops.as_posix().startswith("/content/drive/") else f"Saved tile {number}."
            remaining = [n for n in queue if progress["reviewed"].get(self.ids[n - 1]) != self.token(labels[self.ids[n - 1]])]
            number = next((n for n in remaining if n > number), (remaining or [number])[0])
        elif action == "previous":
            number = next((n for n in reversed(queue) if n < number), (queue or [number])[0])
        elif action == "skip":
            number = next((n for n in queue if n > number), (queue or [number])[0])
        elif action == "go":
            if number not in queue:
                mode = "all"
        elif action == "filter":
            number = None
        elif action != "reload":
            raise ValueError("Unknown review action.")
        return self.state(number, mode, message)


def review_html(state):
    def values(side):
        return "".join(f'<button type="button" data-side="{side}" data-value="{i}" aria-pressed="{str(str(i) == state[side]).lower()}">{i}</button>' for i in range(16))

    suggestions = " ".join(f"{flag['side'].upper()}: saved {flag['current']}, suggested {flag['proposed']}." for flag in state["flags"])
    sides = "".join(f'''<section class="half"><h3>{side.upper()} · {'left' if side == 'a' else 'right'} half</h3>
      <img src="data:image/png;base64,{state['images'][side]}" alt="{side.upper()} half of tile {state['number']}">
      <div class="values" role="group" aria-label="Pip value for {side.upper()}">{values(side)}</div>
      <p>Selected: <strong data-selected="{side}">{escape(state[side]) or 'Choose a value'}</strong></p></section>''' for side in ("a", "b"))
    options = "".join(f'<option value="{value}"{" selected" if value == state["mode"] else ""}>{label}</option>'
                      for value, label in [("flagged", f"Flagged ({state['flag_count']})"), ("all", f"All tiles ({state['total']})"), ("unreviewed", "Unreviewed")])
    payload = escape(json.dumps({k: state[k] for k in ("number", "a", "b", "token", "mode")}), quote=True)
    complete = '<p class="complete">Review complete for this view. Choose All tiles to keep reviewing.</p>' if state["complete"] else ''
    return f'''<fieldset data-state="{payload}">
      <header><div><h2>Check pip labels</h2><p>{state['reviewed']} / {state['total']} tiles reviewed · {state['remaining']} left in this view</p></div>
        <label>View <select name="mode">{options}</select></label></header>
      {complete}<p class="saved" role="status">{escape(state['message'])}</p>
      <nav><button type="button" data-action="previous">← Previous</button>
        <label>Tile <input name="number" type="number" min="1" max="{state['total']}" value="{state['number']}"></label>
        <button type="button" data-action="go">Go</button><button type="button" data-action="skip">Skip →</button></nav>
      <p class="caption">Tile {state['number']} · {escape(state['image'])} · {escape(state['status'])}{' · Reviewed' if state['is_reviewed'] else ''}</p>
      {'<p class="suggestion">Please check: ' + escape(suggestions) + '</p>' if suggestions else ''}
      <div class="halves">{sides}</div>
      <footer><button type="button" class="primary" data-action="save">Save &amp; next →</button>
        <button type="button" data-action="reject">Reject unreadable crop</button>
        <button type="button" data-action="reload">Reload tile</button></footer>
      <p class="hint">Choose both pip values, then Save &amp; next. Your selections start with the saved labels.</p>
    </fieldset>'''


def open_pip_label_review(crops):
    from google.colab import output
    from IPython.display import HTML, JSON, display

    review = PipLabelReview(crops)
    panel_id = "pip-review-" + uuid4().hex

    def update(action, number, a, b, expected, mode):
        try:
            return JSON({"html": review_html(review.act(action, number, a, b, expected, mode))})
        except (ValueError, OSError) as error:
            return JSON({"error": str(error)})

    output.register_callback(panel_id, update)
    style = '''<style>
      #PANEL{font:15px/1.5 system-ui,sans-serif;max-width:940px;color:#17212b;background:#f6f8fa;border:1px solid #d5dce2;border-radius:18px;padding:24px;color-scheme:light}
      #PANEL *{box-sizing:border-box}#PANEL fieldset{border:0;padding:0;margin:0;min-width:0}#PANEL h2{font-size:24px;margin:0}#PANEL h3{margin:0 0 10px;font-size:17px}
      #PANEL header{display:flex;justify-content:space-between;gap:12px;align-items:center}#PANEL header p{margin:4px 0;color:#526271}
      #PANEL button,#PANEL select,#PANEL input{font:inherit;border:1px solid #bcc8d2;background:white;color:#17212b;border-radius:9px;padding:9px 12px}
      #PANEL button{cursor:pointer;min-height:44px}#PANEL button:hover{background:#edf3ff}#PANEL button:focus-visible{outline:3px solid #6387ef;outline-offset:2px}
      #PANEL button[aria-pressed=true]{background:#265bc5;border-color:#265bc5;color:white;box-shadow:0 0 0 2px #b4cbff}
      #PANEL nav,#PANEL footer{display:flex;gap:10px;align-items:center;flex-wrap:wrap}#PANEL nav{margin-top:20px}#PANEL input{width:90px}
      #PANEL .halves{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin:18px 0}#PANEL .half{background:white;border:1px solid #d5dce2;border-radius:12px;padding:16px}
      #PANEL .half img{display:block;width:100%;max-width:384px;aspect-ratio:1;object-fit:contain;margin:auto auto 16px;border-radius:6px}
      #PANEL .values{display:grid;grid-template-columns:repeat(8,minmax(0,1fr));gap:6px}#PANEL .values button{padding:8px 0;font-weight:650}
      #PANEL .half p{margin:10px 0 0}#PANEL .primary{background:#265bc5;border-color:#265bc5;color:white;font-weight:650;padding:12px 20px}
      #PANEL .suggestion{background:#fff4db;border:1px solid #ecd5a3;padding:10px 14px;border-radius:9px}#PANEL .saved{color:#176239;margin:8px 0}
      #PANEL .complete{background:#dff5e8;padding:12px;border-radius:9px}#PANEL .hint,#PANEL .caption{font-size:13px;color:#526271}#PANEL [role=alert]{color:#a92222;font-weight:600}
      @media(max-width:600px){#PANEL{padding:14px}#PANEL .halves{grid-template-columns:1fr}#PANEL header{align-items:flex-start;flex-direction:column}}
    </style>'''.replace('PANEL', panel_id)
    script = '''<script>(()=>{
      const panel=document.getElementById('PANEL');
      let dirty=false,busy=false;
      async function act(action){
        if(busy)return;
        const fields=panel.querySelector('fieldset'),state=JSON.parse(fields.dataset.state);
        if(dirty&&!['save','reject'].includes(action)&&!confirm('Discard unsaved selections on this tile?')){
          fields.querySelector('[name=mode]').value=state.mode;return;
        }
        const number=fields.querySelector('[name=number]');
        if(action==='go'&&!number.reportValidity())return;
        const alert=panel.querySelector('[role=alert]');alert.textContent='';
        busy=true;fields.disabled=true;
        try{
          const result=await google.colab.kernel.invokeFunction(panel.id,[action,action==='go'?number.valueAsNumber:state.number,state.a,state.b,state.token,fields.querySelector('[name=mode]').value],{});
          const reply=result.data['application/json'];
          if(reply.error)alert.textContent=reply.error;
          else{fields.outerHTML=reply.html;dirty=false;}
        }catch(error){alert.textContent='Could not save. Check the runtime connection, then retry. '+error;}
        finally{busy=false;const current=panel.querySelector('fieldset');if(current)current.disabled=false;}
      }
      panel.addEventListener('click',event=>{
        const button=event.target.closest('button');if(!button||busy)return;
        if(button.dataset.side){
          const fields=panel.querySelector('fieldset'),state=JSON.parse(fields.dataset.state),side=button.dataset.side;
          state[side]=button.dataset.value;fields.dataset.state=JSON.stringify(state);dirty=true;
          fields.querySelectorAll('[data-side='+side+']').forEach(b=>b.setAttribute('aria-pressed',String(b===button)));
          fields.querySelector('[data-selected='+side+']').textContent=state[side];
        }else if(button.dataset.action)act(button.dataset.action);
      });
      panel.addEventListener('change',event=>{if(event.target.name==='mode')act('filter');});
      panel.addEventListener('keydown',event=>{if(event.key==='Enter'&&event.target.name==='number'){event.preventDefault();act('go');}});
    })();</script>'''.replace('PANEL', panel_id)
    display(HTML(f'<section id="{panel_id}">' + style + review_html(review.state()) + '<p role="alert"></p></section>' + script))
    return review
