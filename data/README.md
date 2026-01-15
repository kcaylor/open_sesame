# Data Provenance Documentation

## Training Data: articles_reviewed.csv

### Source
The training data originates from the `abpoll-open` research project analyzing data and code availability statements in scholarly publications.

**Original Location**: `resources/abpoll-open-b71bd12/data/processed/articles_reviewed.csv`

### Description
Human-coded classification of data and code openness for scholarly articles. Each record represents a publication with:
- Data availability statement text
- Code availability statement text
- Human-coded openness classification for data
- Human-coded openness classification for code

### Schema

| Column | Type | Description |
|--------|------|-------------|
| `authors` | string | Publication author list |
| `title` | string | Publication title |
| `journal` | string | Journal name |
| `doc_type` | string | Document type (Article, Review, etc.) |
| `total_cited` | int | Citation count |
| `doi` | string | Digital Object Identifier |
| `doi_link` | string | DOI URL |
| `pub_year` | int | Publication year |
| `is_climate` | int | Whether climate-related (1/0) |
| `dropped` | int | Whether excluded from analysis (1/0) |
| `dropped_why` | string | Reason for exclusion |
| `data_statement` | string | Data availability statement text |
| `code_statement` | string | Code availability statement text |
| `data_statement_where` | string | Location of data statement |
| `code_statement_where` | string | Location of code statement |
| `data_open` | string | **Ground truth data openness classification** |
| `code_open` | string | **Ground truth code openness classification** |
| `data_repo` | string | Data repository name |
| `code_repo` | string | Code repository name |
| `data_included` | string | What data is included |
| `data_limitation_other` | string | Data limitations/restrictions |
| `code_included` | string | What code is included |
| `data_reasons` | string | Reasons for data classification |
| `code_reasons` | string | Reasons for code classification |
| `notes` | string | Additional notes |

### Classification Taxonomy

The original data uses the following classifications which map to our 4-category taxonomy:

| Original Value | Mapped Category | Description |
|---------------|-----------------|-------------|
| "Closed" | `closed` | Not accessible, includes "upon request" |
| "Partially Closed" | `mostly_closed` | Largely restricted with limited access |
| "Partially Open" | `mostly_open` | Largely accessible with minor restrictions |
| "Open" | `open` | Fully open access, no restrictions |
| "Nothing" | N/A | No statement provided (treated as missing) |

### Classification Rubric

Based on the specification clarifications:

1. **open**: Public repository with no barriers (Zenodo, Figshare, GitHub public)
2. **mostly_open**: Public repository with registration required, institutional access
3. **mostly_closed**: Data use agreements, partial availability, some restrictions
4. **closed**: "Available upon request", confidential, not accessible

### Data Quality Notes

- Some records have `dropped=1` and should be excluded from training
- Records with `is_climate=0` may have different domain characteristics
- Empty statements (`"Nothing"`) indicate no availability statement was found
- Statement text may contain URLs and repository references

### Usage

```python
import pandas as pd

# Load training data
df = pd.read_csv('resources/abpoll-open-b71bd12/data/processed/articles_reviewed.csv')

# Filter to relevant records
df_train = df[
    (df['dropped'] != 1) &
    (df['is_climate'] == 1) &
    (df['data_statement'] != 'Nothing')
]
```

### Citation

If using this data, please cite the original research:

```
Pollack, A. B., et al. (2026). "Unlocking the Benefits of Data and Code Sharing
in Environmental Science." [Journal TBD]
```

### Version History

- **v1.0** (2026-01-15): Initial documentation for openness classification model
