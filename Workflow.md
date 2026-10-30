# Team Working Agreement – MLOps CI/CD-projekt

**Projekt:** Saldes Mobil Churn – CI/CD-pipeline  
**Team:** 4 medlemmar  
**Gäller från:** Projektstart till slutlig inlämning 1 november 2026  
**Syfte:** Att skapa ett strukturerat samarbete där varje person ansvarar för sin del, dokumenterar sitt arbete och bidrar till en gemensam fungerande CI/CD-pipeline.

---

## 1. Våra gemensamma principer

Vi kommer överens om att:

- Arbeta genom GitHub Issues, branches och Pull Requests.
- Aldrig pusha direkt till `main`.
- Ha en tydlig ansvarig person för varje Issue.
- Inte ändra andra personers ansvarsområden utan överenskommelse.
- Göra små och fokuserade commits.
- Dokumentera lösningar, tester, problem och kompromisser.
- Granska varandras Pull Requests före merge.
- Kommunicera ändringar som kan påverka andra teammedlemmar.

Alla ansvarar för att förstå hur deras del passar in i den gemensamma pipelinen.

## 2. Ansvarsfördelning

### Person 1 – CI och GitHub-integration

**Ansvar:**
- GitHub Actions och huvudworkflow.
- Branch protection och obligatoriska kontroller.
- Kodtester och pipelineberoenden.
- Integration av de andra personernas CI-jobb.

**Huvudsakliga filer:**
- `.github/workflows/`
- `.github/actions/`
- CI-relaterad konfiguration.

**Viktigt:** Person 1 ansvarar för samordning av ändringar i huvudworkflowen men äger inte ensam hela projektets CI-design.

### Person 2 – Data och Pandera

**Ansvar:**
- Pandera-schema och datavalidering.
- Kontroller av kolumner, datatyper och värden.
- Positivt test med `kundbas.csv`.
- Negativt test med `kundbas_ny_leverans.csv`.

**Huvudsakliga filer:**
- Datavalideringsmoduler.
- `tests/test_data.py` och nya datatester.
- Eventuell separat konfiguration för Pandera.

**Viktigt:** Person 2 implementerar valideringen. Person 1 hjälper till att koppla den till CI-workflowen.

### Person 3 – Modell och versionering

**Ansvar:**
- Modellträning och utvärdering.
- Modelltester och kvalitetströskel.
- Modellartefakter och spårbarhet.
- Koppling mellan commit, dataset och tränad modell.

**Huvudsakliga filer:**
- `src/churn/model.py`
- `src/churn/evaluate.py`
- `tests/test_model.py`
- Modellrelaterade konfigurationsfiler.

**Viktigt:** Person 3 ansvarar för modellens kvalitet och levererar den godkända artefakt som Docker-jobbet ska använda.

### Person 4 – Docker och distribution

**Ansvar:**
- Dockerfile och containerkonfiguration.
- Smoke-test.
- Byggande av Docker-image.
- Publicering till GitHub Container Registry (`ghcr.io`).

**Huvudsakliga filer:**
- `Dockerfile`
- `.dockerignore`
- Smoke-test och eventuella startskript.
- Containerrelaterad konfiguration.

**Viktigt:** Person 4 ska använda den modell som person 3 har fått godkänd, inte träna en ny modell i Docker-jobbet.

## 3. Regler för filägarskap

För att undvika merge-konflikter gäller följande:

1. Varje person arbetar i första hand med filerna inom sitt ansvarsområde.
2. Om någon behöver ändra en fil som tillhör en annan persons område ska detta först diskuteras.
3. Filer som `.github/workflows/ci.yml`, `pyproject.toml` och `uv.lock` betraktas som gemensamma integrationsfiler.
4. Ändringar i gemensamma filer ska samordnas innan arbetet påbörjas.
5. Två personer ska inte samtidigt göra större ändringar i samma gemensamma fil utan en överenskommen plan.

**Särskild regel för `ci.yml`:**

Person 1 samordnar ändringar i huvudworkflowen. Övriga personer får föreslå och implementera förändringar, men ska först dokumentera behovet i sitt Issue och samordna tidpunkten för integrationen.

## 4. GitHub Issues – Vårt arbetssätt

Varje större uppgift ska ha ett separat GitHub Issue.

Varje Issue ska innehålla:

- **Problem:** Vad behöver lösas?
- **Goal:** Vad ska fungera när uppgiften är klar?
- **Owner:** Vem ansvarar?
- **Scope:** Vilka filer och komponenter berörs?
- **Acceptance criteria:** Hur verifierar vi att lösningen fungerar?
- **Dependencies:** Vad måste vara klart först?
- **Documentation:** Vilka tester, beslut och resultat ska dokumenteras?

Ett Issue ska endast ha en huvudansvarig, men andra personer får hjälpa till genom diskussioner och kodgranskning.

### Arbetsstatus

Vi använder följande statusar:

- **Backlog:** Inte påbörjad.
- **Ready:** Uppgiften är definierad och redo.
- **In Progress:** Ansvarig arbetar med uppgiften.
- **In Review:** Pull Request skapad.
- **Blocked:** Uppgiften väntar på något.
- **Done:** PR mergad, verifierad och dokumenterad.

En person bör normalt inte ha fler än ett större Issue i statusen In Progress samtidigt.

## 5. Git och branchregler

Vi använder en separat branch för varje Issue.

**Namngivning:**
- `feature/issue-12-pandera-validation`
- `fix/issue-15-model-evaluation`
- `ci/issue-18-workflow-integration`
- `docs/issue-20-pipeline-report`

Varje branch ska utgå från senaste `main`, om inte teamet har kommit överens om något annat.

Vi använder Conventional Commits:

- `feat:` – Ny funktionalitet.
- `fix:` – Felrättning.
- `test:` – Nya eller förbättrade tester.
- `ci:` – Ändringar i CI/CD.
- `refactor:` – Omstrukturering utan ändrat beteende.
- `docs:` – Dokumentation.
- `chore:` – Underhåll.

Commits ska vara små och beskriva en tydlig förändring.

## 6. Pull Requests och kodgranskning

Ingen får merga sin egen PR utan att en annan teammedlem först har granskat och godkänt den.

Varje PR ska:

1. Länkas till sitt Issue.
2. Beskriva vad som ändrats och varför.
3. Redovisa hur förändringen testats.
4. Uppfylla relevanta acceptance criteria.
5. Ha gröna obligatoriska CI-kontroller.
6. Godkännas av minst en annan teammedlem.

Granskaren ska kontrollera kodens funktion, läsbarhet, testning och möjliga konsekvenser för övriga delar av projektet.

**Förslag på granskningsfördelning:**

- Person 1 granskas av person 2.
- Person 2 granskas av person 3.
- Person 3 granskas av person 4.
- Person 4 granskas av person 1.

Alla ska ha skapat minst en mergad Pull Request och granskat minst en annan persons PR.

## 7. Definition of Done

Ett Issue får markeras som Done först när:

- Funktionaliteten är implementerad.
- Relevanta tester har körts.
- CI är grön, eller ett avsiktligt negativt test har dokumenterats.
- PR har granskats och mergats.
- Resultat och eventuella kompromisser har dokumenterats i GitHub Issue.
- Ändringen fungerar tillsammans med de andra delarna av projektet.

För datavalideringen krävs både ett lyckat test med originaldata och ett misslyckat test med felaktig data.

För Docker krävs en byggd image, ett godkänt smoke-test och verifierad publicering.

## 8. Dokumentationsregler

Vi dokumenterar arbetet löpande, inte bara vid projektets slut.

Varje avslutat Issue ska ha en avslutande kommentar med:

- **Problem**
- **Solution**
- **Verification**
- **Related commits / Pull Request**
- **Trade-offs**
- **Conclusion**

Vi dokumenterar även misslyckade experiment, eftersom de visar att kvalitetsgrindar och säkerhetsmekanismer fungerar.

Tekniska beslut som påverkar flera ansvarsområden ska dokumenteras så att hela teamet kan förstå varför lösningen valdes.

## 9. Kommunikation och blockerande problem

Om en person upptäcker ett problem som påverkar någon annans arbete ska personen:

1. Skriva en kommentar i relevant Issue.
2. Meddela den berörda personen.
3. Markera uppgiften som Blocked om arbetet inte kan fortsätta.
4. Föreslå en lösning innan gemensamma filer ändras.

Vi försöker lösa blockerande problem tillsammans utan att någon person behöver ta över en annan persons hela ansvarsområde.

Vid en akut felrättning får ansvarsområden frångås efter överenskommelse. Ändringen måste fortfarande dokumenteras och granskas.

## 10. Samarbete kring integration

Integration ska ske stegvis.

Vi arbetar i följande huvudsakliga ordning:

1. Repository, branch protection och grundläggande tester.
2. Pandera-datavalidering.
3. Modellträning och kvalitetsgrind.
4. Modellversionering och spårbara artefakter.
5. Docker-paketering och smoke-test.
6. Publicering till containerregister.
7. Fullständig verifiering och rapport.

Olika personer får arbeta parallellt med sina komponenter, men beroenden ska vara kända innan integrationen sker.

Ingen får medvetet merga en förändring som gör `main` oanvändbar.

## 11. Individuellt arbete för VG

De gemensamma projektkraven prioriteras först.

Eventuellt individuellt VG-arbete organiseras i separata Issues och Pull Requests.

VG-förbättringar ska:
- Ha en tydlig individuell ansvarig.
- Vara förbättringar utöver den gemensamma grundlösningen.
- Motiveras tekniskt.
- Innehålla relevanta mätningar före och efter.
- Inte försämra teamets färdiga pipeline.

Varje person ansvarar för sin individuella rapport och sina egna PR-referenser.

## 12. Inlämning och ansvar

**Gemensamt ansvar:**
- Fungerande CI/CD-pipeline.
- Grön fullständig körning.
- Körning som stoppas av Pandera.
- Gemensam rapport på 1–2 sidor.
- Dokumentation av AI-användning.

**Individuellt ansvar:**
- Länkar till egna mergade Pull Requests.
- Länkar till genomförda PR-reviews.
- Eventuell VG-rapport med mätvärden.

Alla förväntas kunna förklara sin egen implementation och dess roll i den gemensamma pipelinen.

## 13. Godkännande av kontraktet

Genom att godkänna detta dokument förbinder vi oss att följa ovanstående arbetssätt och samarbeta för att leverera en fungerande CI/CD-pipeline.

| Teammedlem | Ansvarsområde | Godkännande |
|---|---|---|
| Person 1 | CI och integration | |
| Person 2 | Data och Pandera | |
| Person 3 | Modell och versionering | |
| Person 4 | Docker och distribution | |

**Ändringar i kontraktet:** Kan göras genom en dokumentations-PR som granskas och godkänns av samtliga fyra teammedlemmar.
