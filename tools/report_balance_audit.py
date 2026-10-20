"""Summarize opening probes and conditional real-reward/shop economy experiments."""
import csv
import gzip
import json
import statistics as st
import sys
from collections import defaultdict
from pathlib import Path


def load(path):
    path = Path(path)
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def median(values):
    return round(st.median(values), 2) if values else None


def summarize(prefix):
    opening = load(prefix + "_opening.csv")
    economy = load(prefix + "_economy.csv")
    offer_path = prefix + "_offers.csv"
    offers = load(offer_path if Path(offer_path).exists() else offer_path + ".gz")
    applied = "afford_current" in offers[0]
    result = {"opening": [], "wealth": [], "offers": [], "access": [], "shopper": []}
    for hp in sorted({int(r["opening_hp"]) for r in opening}):
        for policy in ("greedy", "tactical"):
            rows = [r for r in opening if int(r["opening_hp"]) == hp and r["policy"] == policy]
            first = [r for r in rows if r["encounter"] == "1"]
            n = len(first)
            result["opening"].append({"hp": hp, "policy": policy, "n": n,
                "first_wins": sum(int(r["won"]) for r in first),
                "stage_wins": sum(int(r["won"]) for r in rows if r["encounter"] == "3"),
                "first_hp_median": median([int(r["hp"]) for r in first if r["won"] == "1"]),
                "first_hands_median": median([int(r["turns"]) for r in first]),
                "first_hands_max": max(int(r["turns"]) for r in first),
                "timeouts": sum(int(r["timeout"]) for r in rows)})
    for policy, unused in (("save", "0"), ("save", "2"), ("shopper", "0")):
        for fight in (1, 2, 3, 6, 9, 12, 30, 60):
            rows = [r for r in economy if r["policy"] == policy and r["unused_hands"] == unused and int(r["fight"]) == fight]
            result["wealth"].append({"policy": policy, "unused": int(unused), "fight": fight,
                "gold_median": median([int(r["gold"]) for r in rows]),
                "souls_median": median([int(r["souls"]) for r in rows]),
                "spent_mean": round(st.mean(int(r["spent"]) for r in rows), 2),
                "strong_bought_mean": round(st.mean(int(r["strong_bought"]) for r in rows), 2)})
    group = defaultdict(list)
    for r in offers:
        if r["policy"] == "save" and r["unused_hands"] == "0":
            group[r["group"], r["currency"], "early" if int(r["stage"]) <= 3 else "late"].append(r)
    for (kind, currency, period), rows in sorted(group.items()):
        if kind not in {"spn_epic_plus", "gear_tier4_plus", "gear_other", "soul_relic", "card_evolution2"}:
            continue
        result["offers"].append({"group": kind, "currency": currency, "period": period, "n": len(rows),
            "price_min": min(int(r["cost"]) for r in rows), "price_median": median([int(r["cost"]) for r in rows]),
            "price_max": max(int(r["cost"]) for r in rows),
            "affordable_pct": round(100 * st.mean(int(r["afford_current" if applied else "afford6"]) for r in rows), 2),
            "free_pct": round(100 * st.mean(int(r["free"]) for r in rows), 2)})
    for kind in ("spn_epic_plus", "gear_tier4_plus", "soul_relic", "card_evolution2"):
        by_seed = defaultdict(list)
        for r in offers:
            if r["policy"] == "save" and r["unused_hands"] == "0" and r["group"] == kind:
                by_seed[r["seed"]].append(r)
        n = len({r["seed"] for r in economy})
        for multiplier in (("current",) if applied else (6, 4)):
            key = "afford_current" if applied else f"afford{multiplier}"
            first = [min(int(r["fight"]) for r in rows if r[key] == "1")
                     for rows in by_seed.values() if any(r[key] == "1" for r in rows)]
            free = sum(any(r["free"] == "1" for r in rows) for rows in by_seed.values())
            result["access"].append({"group": kind, "multiplier": multiplier, "routes": n,
                "ever_affordable_pct": round(100 * len(first) / n, 2),
                "first_affordable_fight_median": median(first),
                "affordable_by_fight9_pct": round(100 * sum(f <= 9 for f in first) / n, 2),
                "ever_free_pct": round(100 * free / n, 2)})
    end = [r for r in economy if r["policy"] == "shopper" and r["fight"] == "60"]
    early = [r for r in economy if r["policy"] == "shopper" and r["fight"] == "9"]
    result["shopper"] = {"routes": len(end),
        "strong_mean": round(st.mean(int(r["strong_bought"]) for r in end), 2),
        "free_strong_mean": round(st.mean(int(r["free_strong"]) for r in end), 2),
        "ever_free_strong_pct": round(100 * st.mean(int(r["free_strong"]) > 0 for r in end), 2),
        "early_any_strong_pct": round(100 * st.mean(int(r["strong_bought"]) > 0 for r in early), 2)}
    result["counts"] = {"opening_fights": len(opening), "economy_rows": len(economy), "offers": len(offers)}
    Path(prefix + "_summary.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    return result


if __name__ == "__main__":
    data = summarize(sys.argv[1])
    for key in ("opening", "wealth", "access", "shopper", "counts"):
        print(key, json.dumps(data[key], ensure_ascii=False))
