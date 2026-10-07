# -*- coding: utf-8 -*-
import json
from pathlib import Path

root = json.loads(
    Path(r"C:\Users\bilaw\AndroidStudioProjects\fixxi\assets\Dataset.json").read_text(
        encoding="utf-8"
    )
)
eng = root["diagnostic_engine"]
keys = []


def add(k, s):
    if isinstance(s, str) and s.strip():
        keys.append({"k": k, "ru": s.strip()})
    elif isinstance(s, list):
        for i, x in enumerate(s):
            add("%s.%s" % (k, i), x)


for h in eng.get("hazards", []):
    hid = h["id"]
    add("hazard.%s.label" % hid, h.get("label"))
    add("hazard.%s.safety" % hid, h.get("safety"))
add("hazard_default_checks", eng.get("hazard_default_checks"))
for a in eng.get("appliances", []):
    aid = a["id"]
    add("%s.common_checks" % aid, a.get("common_checks"))
    add("%s.common_safety" % aid, a.get("common_safety"))
    for f in a.get("faults", []):
        p = "%s.%s" % (aid, f["symptom"])
        add("%s.label" % p, f.get("label"))
        add("%s.checks" % p, f.get("checks"))
        add("%s.safety" % p, f.get("safety"))
        for j, iss in enumerate(f.get("issues") or []):
            add("%s.issue.%s.title" % (p, j), iss.get("title"))
            add("%s.issue.%s.cause" % (p, j), iss.get("cause"))

out = Path(r"C:\Users\bilaw\AndroidStudioProjects\fixxi\tool\diag_strings.json")
out.write_text(json.dumps(keys, ensure_ascii=False, indent=2), encoding="utf-8")
print(len(keys), "wrote", out)
