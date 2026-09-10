# Haemoglobin custom files

Put fork-specific assets here to avoid touching upstream paths:

- `branding/` — future icons, logos, QRC overrides
- `docs/` — your own docs

Rule: prefer ADDING files here over EDITING `launcher/`, `libraries/`, `cmake/`.
When you must edit upstream files, wrap changes with:

```
# HAEMOGLOBIN: <reason>
...
# END HAEMOGLOBIN
```

so merges stay trivial.
