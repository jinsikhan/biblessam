# Stitch – Bible Project Screens

Exported from [Google Stitch](https://stitch.googleapis.com/mcp) for reference and implementation.

## Project

- **Title:** Bible  
- **Project ID:** `10112272476937199624`

## Screens

### 1. Home Screen

| Field       | Value |
|------------|--------|
| **Screen ID** | `f1e71fdd78b041339281201309fdf4f2` |
| **Title**     | Home Screen |
| **Dimensions** | 780 × 3422 (design) |
| **Device**     | MOBILE |
| **Theme**      | LIGHT, Manrope, roundness 8, primary `#49ec13` |

**Files in this folder:**

- `home-screen.png` – Screenshot (hosted URL downloaded with `curl -L`)
- `home-screen.html` – HTML/CSS export (Tailwind, Manrope)

**Design prompt (from Stitch):**  
BibleSsam Home Screen. Features: Top Search Bar; Reading Streak Banner (7 days, 6/10 mins); Today's Word Card (John 3, Read button); "How are you feeling?" chips (Comfort, Grateful, Anxious, Courage, Love, Wisdom); OT/NT Recommendations; Recently Read; Today's One-Line Prayer. Clean, vertically scrollable, soft card components.

## Re-downloading

To refresh assets, use the Stitch MCP or REST:

```bash
# Get screen JSON (includes screenshot and htmlCode downloadUrl)
curl -sS -L -H "X-Goog-Api-Key: YOUR_API_KEY" \
  "https://stitch.googleapis.com/v1/projects/10112272476937199624/screens/f1e71fdd78b041339281201309fdf4f2"

# Then download each downloadUrl with:
curl -L -o home-screen.png "<screenshot.downloadUrl>"
curl -L -o home-screen.html "<htmlCode.downloadUrl>"
```
