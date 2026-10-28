# Churnmodellen – Saldes Mobil AB

> *Saldes Mobil AB är ett påhittat företag och all kunddata är fiktiv. Repot är en övning i
> kursen Kontinuerlig integration och leverans (MLOps25, Nackademin).*

## Välkommen till teamet

Hej och välkommen!

Kul att du börjar hos oss som MLOps-ingenjör. Här är bakgrunden till ditt första uppdrag.

Vi tappar kunder. Analysteamet har byggt en modell som förutsäger vilka kunder som riskerar
att säga upp sitt abonnemang. Varje måndag får kundtjänst en **ringlista** med de kunder som
har högst risk, och ringer dem med ett erbjudande.

I dag sköts det mesta för hand. Modellen tränas på en dator här på kontoret, och modellfilen
ligger incheckad i `models/`. Ringlistan gör någon varje måndag morgon med kommandona nedan.
Vi har ett CI-workflow, men det kör allt i ett enda jobb, installerar om alla paket vid
varje push och testar på en annan Python-version än servern som gör ringlistan (3.11).
Sedan förra veckan är det dessutom rött, och ingen har hunnit ta reda på varför.

För två veckor sedan gick det riktigt fel. Kundtjänst fick en ringlista från en modell som
var sämre än den förra. Ingen märkte det förrän säljarna klagade, och ingen kunde säga vilken
commit eller vilken data modellen kom från.

**Ditt uppdrag:** se till att bara en testad modell med känd härkomst kan bli en ringlista.
Jag har skrivit ärenden åt dig, se *Kom igång* nedan.

Två regler:

- Ändra inte modellen, datan eller feature-koden i `src/churn/data.py`. Den sköter
  analysteamet. Ditt arbete är workflows, tester och inställningar i repot.
- Ingen pushar direkt till main när vi väl har skydd på plats. Allt går via pull requests.

Lycka till, och fråga hellre en gång för mycket.

*Teamleaden*

## Kom igång

1. Skapa ditt eget repo från mallen: **Use this template → Create a new repository**.
   Välj ditt eget konto och **Public**.
2. Klona det och skapa ärendena som issues (kräver `gh auth login`):

   ```bash
   git clone https://github.com/<ditt-användarnamn>/<ditt-repo>.git
   cd <ditt-repo>
   bash arenden/skapa.sh
   ```

3. Öppna fliken **Actions** och titta på den första körningen. Börja med ärende F1.

## Så kör man det lokalt med uv

### Installera dependencies
```
uv sync --frozen --extra dev --extra training
```
MLflow och Pandera installeras med `--extra training` för träning,
validering och tester. Docker-imagen för ringlistan använder bara
grundberoendena och innehåller därför inte dessa paket.

### Kör den kompletta ML pipelinen
```bash
# Tests
uv run --frozen --no-sync python -m pytest -v 
# Datavalidering
uv run --frozen --no-sync python -m kontroller.validate_data data/kundbas.csv
# Tränar, skriver outputs/modell.joblib och outputs/matvarden.json
uv run --frozen --no-sync python -m churn.model
# Kvalitetsgrind: felkod om ROC AUC är under tröskeln
uv run --frozen --no-sync python -m churn.evaluate
# Skriver outputs/ringlista.csv
uv run --frozen --no-sync python -m churn.score
```


## Vad som finns här

| Sökväg | Innehåll |
| --- | --- |
| `data/kundbas.csv` | 2 000 kunder: ålder, region, abonnemang, kostnad, dataförbrukning, supportärenden och om kunden avslutat (`avslutat`) |
| `src/churn/data.py` | Inläsning och features |
| `src/churn/model.py` | Träning. Skriver modell och mätvärden till `outputs/` |
| `src/churn/evaluate.py` | Kvalitetsgrind på mätvärdena |
| `src/churn/score.py` | Ringlistan |
| `tests/` | Tester på tre nivåer: kod, data och modell |
| `outputs/modell.joblib` |  Modellen som skapas när träningen körs. Sparas inte i Git |
| `arenden/` | Ärendena, och `skapa.sh` som gör dem till issues |
| `.github/workflows/ci.yml` | Vårt CI |

## Modellen och kvalitetskontrollen

Vi använder ROC AUC för att kontrollera modellen. Gränsen är 0,70:
om resultatet är lägre stoppas körningen. Vi kontrollerar också att
resultatet och den valda gränsen är giltiga tal mellan 0 och 1.

Modellen jämförs med en enkel DummyClassifier. Båda använder samma
uppdelning med 25 % testdata, så att jämförelsen görs på samma kunder.

Den gamla modellen i `models/modell.joblib` är borttagen från Git.
När du kör träningskommandot ovan får du en ny modell i
`outputs/modell.joblib`. Resultaten sparas i `outputs/matvarden.json`,
tillsammans med information om vilken kod och data som användes.

Kör sedan utvärderingskommandot ovan för att kontrollera om modellen
blir godkänd. Modellen och resultaten i `outputs/` ignoreras av Git
via `.gitignore` och följer därför inte med i vanliga commits.

## MLflow

MLflow sparar parametrar, mätvärden, commit och datasetets hash
när modellen tränas. Varje körning sparar också en kopia av
`modell.joblib` och `matvarden.json`.

I CI sparas resultaten i ett artifact som heter `mlflow-<commit SHA>`.

### Kör lokalt

Kör från projektets huvudmapp:

```bash
uv sync --locked --extra dev --extra training
uv run --locked --extra training python -m churn.model
uv run --locked python -m churn.evaluate
uv run --locked --extra training mlflow ui --backend-store-uri sqlite:///mlflow.db --port 5001
```

Öppna http://127.0.0.1:5001 och välj `mobil-churn` under
Model training. Stoppa gränssnittet med Ctrl+C.

Lokala resultat sparas i `mlflow.db` och `mlruns/`.
De sparas inte i Git.

### Öppna resultat från CI

Ladda ner artifactet `mlflow-…` från GitHub Actions.
Packa upp ZIP-filen och kopiera `mlflow-tracking.tar.gz` till `outputs/`.

Använd en ny, tom mapp och kör:

```bash
mkdir -p outputs/mlflow-ci
tar -xzf outputs/mlflow-tracking.tar.gz -C outputs/mlflow-ci
uv run --locked python scripts/restore_mlflow.py outputs/mlflow-ci
uv run --locked --extra training mlflow ui --backend-store-uri sqlite:///outputs/mlflow-ci/mlflow.db --port 5001
```

Stoppa ett eventuellt öppet MLflow-gränssnitt innan du startar ett nytt
på samma port.

Öppna http://127.0.0.1:5001 och välj `mobil-churn`.
Nu kan du se resultaten från CI utan att träna modellen igen.

Skriptet uppdaterar sökvägarna i den nedladdade databasen och sparar
en backup. Modellen ändras inte. När gränssnittet är stängt kan
den extraherade mappen tas bort.

### Varning vid tester

Testerna kan visa en varning om `noload`, som används internt av
MLflow med SQLAlchemy och är markerat för framtida borttagning.
Vi har lämnat varningen synlig. Alla 28 tester passerar.