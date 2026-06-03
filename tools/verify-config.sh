#!/usr/bin/env bash
# verify-config.sh — config-completeness gate for agents.config.yaml + pipeline_state enum.
#
# The adoption pain (C-UAS migration, 2026-06): agents.config.yaml was hand-rebuilt and
# eyeballed, and PROGRESS.md drifted from the schema. This converts that manual audit into
# one command, so adopters (and this repo) catch the gaps mechanically. Per JCC workflow
# research (ledger job jcc-workflow-research-001).
#
# Checks:
#   1. Every DISPATCHED agent under `agents:` has family/model/loads_bundle/adapter, and a
#      `sandbox:` field — EXCEPT the orchestrator (`is_orchestrator: true`), which is never
#      dispatched through the shim and correctly has no sandbox. HARD FAIL.
#   2. The governance blocks `role_eligibility:`, `validation:`, `policy:` all exist, and
#      `validation:` declares `cross_family_evaluator_required` + `cross_family_truthsayer_required`
#      (INV 1.A). HARD FAIL if missing.
#   3. Enum drift: every `pipeline_state: <v>` referenced under `commands/` is listed in the
#      canonical enum in `60-schemas/progress.md`. HARD FAIL on any unknown value.
#
# Exit 0 = complete. Exit 1 = a gap.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

python3 - <<'PY'
import re, sys, pathlib, glob
fail = 0
cfg = pathlib.Path("agents.config.yaml").read_text().splitlines()

# --- locate top-level blocks ---
tops = {}
for i, ln in enumerate(cfg):
    m = re.match(r'^([a-z_]+):', ln)
    if m:
        tops.setdefault(m.group(1), i)

# --- Check 2: governance blocks present ---
for blk in ("role_eligibility", "validation", "policy", "agents"):
    if blk not in tops:
        print(f"FAIL: agents.config.yaml missing top-level `{blk}:` block"); fail = 1

# validation cross-family flags
val_txt = "\n".join(cfg[tops.get("validation", 0):])
for flag in ("cross_family_evaluator_required", "cross_family_truthsayer_required"):
    if not re.search(rf'{flag}:\s*true', val_txt):
        print(f"FAIL: validation block missing `{flag}: true` (INV 1.A)"); fail = 1

# --- Check 1: agent completeness ---
if "agents" in tops:
    start = tops["agents"] + 1
    ends = [v for v in tops.values() if v > tops["agents"]]
    end = min(ends) if ends else len(cfg)
    block = cfg[start:end]
    agents = {}
    cur = None
    for ln in block:
        m = re.match(r'^  ([A-Za-z0-9_-]+):\s*$', ln)
        if m:
            cur = m.group(1); agents[cur] = []
        elif cur is not None:
            agents[cur].append(ln)
    for name, body in agents.items():
        txt = "\n".join(body)
        is_orch = bool(re.search(r'is_orchestrator:\s*true', txt))
        required = ["family", "model", "loads_bundle", "adapter"]
        if not is_orch:
            required.append("sandbox")
        for field in required:
            if not re.search(rf'^\s+{field}:', txt, re.M):
                role = "orchestrator" if is_orch else "worker"
                print(f"FAIL: agent `{name}` ({role}) missing `{field}:`"); fail = 1
        if is_orch and re.search(r'^\s+sandbox:', txt, re.M):
            print(f"WARN: orchestrator `{name}` has a `sandbox:` field — it is never dispatched; remove it.")

# --- Check 3: pipeline_state enum drift ---
prog = pathlib.Path("60-schemas/progress.md").read_text()
m = re.search(r'pipeline_state:\s*\{([^}]*)\}', prog)
enum = set()
if m:
    enum = {v.strip() for v in m.group(1).split("|")}
else:
    print("FAIL: could not find pipeline_state enum in 60-schemas/progress.md"); fail = 1
# Scan commands/ + 20-roles/ + 10-pipeline/ (not commands alone — a state can be
# referenced in a role contract or the lifecycle). On any line that mentions
# `pipeline_state`, every full-backtick `lowercase-hyphen` token is a candidate state
# value. Counters (have `_`) and file refs (have `.`) do not match this token shape, so
# they are excluded automatically. Every candidate MUST be in the canonical enum — this
# catches both assignment-form drift AND precondition-prose pseudo-states.
referenced = {}
for f in sorted(glob.glob("commands/*.md") + glob.glob("20-roles/*.md") + glob.glob("10-pipeline/*.md")):
    for i, ln in enumerate(pathlib.Path(f).read_text().splitlines(), 1):
        if "pipeline_state" not in ln:
            continue
        # (a) full-backtick state tokens on the line (comparison/precondition prose),
        # (b) assignment form `pipeline_state: <state>` / `= <state>` / `: 'state'` (backtick,
        #     single/double quote, or bare). Counters (`_`) and file refs (`.`) do not match
        #     the [a-z-]+ token shape, so they are excluded automatically.
        cands = re.findall(r'`([a-z][a-z-]+)`', ln)
        cands += re.findall(r"pipeline_state\s*[:=]\s*[\x60'\"]?([a-z][a-z-]+)", ln)
        for tok in cands:
            referenced.setdefault(tok, f"{f}:{i}")
for v, src in sorted(referenced.items()):
    if enum and v not in enum:
        print(f"FAIL: `{v}` used as a pipeline_state value ({src}) is not in the canonical enum {sorted(enum)}"); fail = 1

print("---")
if fail:
    print("verify-config: FAIL — config/enum completeness gap above.")
    sys.exit(1)
print(f"verify-config: OK — agents complete; governance blocks present; canonical pipeline_state enum covers all {len(referenced)} backtick states referenced across commands/, 20-roles/, 10-pipeline/.")
PY
