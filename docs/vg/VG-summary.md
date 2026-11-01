# Individuellt VG-arbete – Docker Security & CI Optimization

## Bakgrund och syfte

I gruppens CI/CD-projekt utvecklade vi en pipeline som testar, validerar, tränar och paketerar en ML-modell för att förutsäga kundbortfall (churn).

Efter att gruppens grunduppgift var färdig skapade jag en egen GitHub-fork för att undersöka förbättringar av pipelinens säkerhet och resurshantering.

Mitt individuella VG-arbete består av två separata förbättringar:

1. Förbättrad containersäkerhet genom non-root-körning.
2. Effektivare Docker-byggning genom persistent Buildx-cache i GitHub Actions.

Båda förbättringarna har implementerats i separata Pull Requests och mergats till min fork.

## VG 1 – Docker Security Optimization

### Problem

Den ursprungliga Docker-containern körde ML-applikationen som root (UID 0), trots att applikationen inte behövde administratörsbehörigheter.

Det innebar onödigt omfattande körbehörigheter inne i containern.

### Implementering

Jag skapade en dedikerad användare, `churn`, med UID 10001 och ändrade Dockerfile så att applikationen körs under denna användare.

Jag ändrade även ägarskapet för `/app/outputs` för att programmet fortfarande skulle kunna skriva den genererade ringlistan.

### Resultat

| Mätvärde | Före | Efter |
|---|---|---|
| Containeranvändare | root (UID 0) | UID 10001 |
| Byggtid utan cache | 140 s | 109 s |
| Image-storlek | 252 662 433 byte | 252 662 989 byte |
| Smoke-test | PASS | PASS |

### Analys

Säkerhetsförbättringen är verifierad genom att containern nu körs som UID 10001. Funktionaliteten är bevarad, eftersom smoke-testet fortfarande genererar en korrekt ringlista med 100 kunder och kontrollerar hanteringen av en saknad modellfil.

Image-storleken ökade med 556 byte, vilket är försumbart. Byggtiden var 31 sekunder kortare vid eftermätningen, men detta kan inte säkert tillskrivas ändringen eftersom endast en byggning per version mättes.

### Trade-offs

Non-root-körning kräver mer noggrann hantering av filbehörigheter. Vid framtida förändringar av utmatningskataloger måste dessa behörigheter kontrolleras.

Non-root minskar applikationens rättigheter men ersätter inte andra säkerhetsåtgärder, exempelvis begränsade container capabilities och korrekt hantering av hemligheter.

**Pull Request:** https://github.com/BigLurch/mobil-churn-laboration-VG/pull/1

## VG 2 – Docker Buildx Cache Optimization

### Problem

Den ursprungliga CI-pipelinen använde `docker build` på GitHub-hostade runners. Eftersom runners normalt är tillfälliga kunde tidigare lokala bygglager inte förutsättas finnas kvar mellan körningar.

Det innebar att oförändrade beroenden och byggsteg riskerade att behandlas på nytt.

### Implementering

Jag ersatte det vanliga Docker-byggsteget med Docker Buildx och `docker/build-push-action@v6`.

Jag konfigurerade persistent cache med GitHub Actions cache-backend:

- `cache-from: type=gha,scope=churn-vg`
- `cache-to: type=gha,scope=churn-vg,mode=max`

Jag behöll `load: true` så att imagen fortfarande går att smoke-testa lokalt på GitHub Actions-runnern.

### Resultat

| Körning | Total CI-körtid |
|---|---|
| CI #5 – Pull Request | 206 s |
| CI #6 – Efter merge | 181 s |
| CI #7 – Manuell körning | 143 s |

Mellan CI #5 och CI #7 minskade den observerade totala CI-körtiden med 63 sekunder, motsvarande 30,6 %.

Vid den sista verifieringen återanvändes sex Docker-byggsteg från cache, bland annat `pip install uv`, kopiering av beroendefiler och `uv sync --locked`.

### Analys

Byggloggen bekräftar att persistent cache används och att tidigare bygglager återanvänds. Detta minskar behovet av att upprepa oförändrade byggmoment.

De observerade workflow-tiderna minskade över tre körningar. Däremot genomfördes samtliga tre körningar efter Buildx-implementationen, vilket innebär att den exakta tidsvinsten jämfört med ursprunglig `docker build` inte är fastställd.

### Trade-offs

Cacheimport och cacheexport medför overhead, ökad lagringsanvändning och ytterligare komplexitet i GitHub Actions. I en av körningarna tog enbart cacheexporten 31,2 sekunder.

Cache kan också förlora effekt när beroenden eller andra filer som påverkar bygglagren ändras.

Det är därför viktigt att mäta både cacheträffar och total byggtid, i stället för att utgå från att caching alltid gör CI snabbare.

**Pull Request:** https://github.com/BigLurch/mobil-churn-laboration-VG/pull/3

## Samlad slutsats

De två förbättringarna riktar sig mot olika svagheter i den ursprungliga CI/CD-lösningen.

VG 1 förbättrar säkerheten genom att minska applikationens körbehörigheter. VG 2 förbättrar byggprocessens möjlighet att återanvända oförändrade Docker-lager.

Båda förbättringarna har verifierats med GitHub Actions och befintliga smoke-tester, utan att churn-modellens centrala funktionalitet har behövt förändras.

Arbetet har även visat vikten av att skilja på en tekniskt verifierad förändring och en uppmätt prestandaförbättring. En säkerhetsförbättring behöver inte minska image-storleken, och cacheåteranvändning garanterar inte alltid en kortare total CI-körtid.

Den viktigaste lärdomen är att förbättringar i en MLOps-pipeline behöver motiveras, testas och utvärderas utifrån sina faktiska effekter.

## Repository och verifieringsunderlag

Repository: https://github.com/BigLurch/mobil-churn-laboration-VG

- VG 1: https://github.com/BigLurch/mobil-churn-laboration-VG/pull/1
- VG 2: https://github.com/BigLurch/mobil-churn-laboration-VG/pull/3

GitHub Actions-loggarna från CI #5, #6 och #7 används som underlag för cacheanalysen.