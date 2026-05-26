# TAGGING.md

## Hilal Browser sürüm etiketleme rehberi

Bu belge, **Hilal Browser** projesinde hangi adımlarla etiket (tag) oluşturulacağı ve **Firefox** stable sürümünün nasıl tutulacağı hakkında bilgi verir.

---
### 1. Firefox stable sürüm etiketi (tag) nasıl belirlenir?

1. **Otomatik kontrol** – `.github/workflows/check_firefox.yml` her saat başında çalışır ve upstream Firefox deposundaki `FIREFOX_*_RELEASE` tag lerinden en yenisini bulur.
2. **FIREFOX_COMMIT dosyası** – En yeni tag, repository kökündeki `FIREFOX_COMMIT` dosyasına yazılır ve bir commit (`chore: bump Firefox version …`) ile push edilir.
3. **Etkileşimli manuel güncelleme** – Tercih edilen yerel yöntem:
   ```bash
   scripts/select-firefox-version.sh
   git add FIREFOX_COMMIT
   git commit -m "chore: bump Firefox version to <selected tag>"
   git push origin HEAD
   ```
4. **Düşük seviye manuel güncelleme** – Eğer yardımcı script kullanılamıyorsa, şu komutları terminalde çalıştırarak aynı işlemi elle yapabilirsiniz:
   ```bash
   # 1. En yeni stabil tag'i öğren
   git clone --depth 1 --filter=blob:none --no-checkout https://github.com/mozilla-firefox/firefox.git tmp_firefox
   git -C tmp_firefox fetch --tags --quiet
   LATEST_TAG=$(git -C tmp_firefox tag -l 'FIREFOX_*_RELEASE' | sort -V | tail -n1)
   rm -rf tmp_firefox

   # 2. FIREFOX_COMMIT dosyasını güncelle
   echo "$LATEST_TAG" > FIREFOX_COMMIT
   git add FIREFOX_COMMIT
   git commit -m "chore: bump Firefox version to $LATEST_TAG"
   git push origin HEAD
   ```

---
### 2. Hilal Browser kaynağında **proje sürümü** etiketi (tag) oluşturma

Hilal‑Browser kendi kod tabanına da (patch‑set ve overlay) bir sürüm etiketi ekleyerek sürüm takibini yapabilirsiniz.

1. **Etiket adı** – `v<MAJOR>.<MINOR>.<PATCH>` biçiminde olmalıdır (örnek: `v1.4.0`).
2. **Etiketi oluşturma**
   ```bash
   # Değişiklikleriniz commit edilmiş olmalı
   git add .
   git commit -m "feat: some new feature"

   # Tag oluştur ve imzala (gpg imzası varsa)
   git tag -a v1.4.0 -m "Hilal Browser v1.4.0 – based on $LATEST_TAG"
   git push origin v1.4.0
   ```
3. **Etiket açıklaması** – `git tag -a` ile eklenen açıklama, hangi Firefox stable tag'ine (örnek: `FIREFOX_124_0_RELEASE`) dayandığını belirtir. Bu, **reproducibility** için kritiktir.

---
### 3. Etiketleme sürecinde dikkat edilmesi gerekenler

- **Deterministik build**: `FIREFOX_COMMIT` dosyasındaki tag, her geliştiricinin aynı Firefox commit'ini klonlamasını sağlar.
- **Uygulama**: `scripts/setup-firefox.sh` ve `scripts/apply.sh` bu dosyayı okuyarak doğru checkout'i yapar; başka bir dosyaya manuel müdahale edilmez.
- **Tercih edilen yerel araç**: `scripts/select-firefox-version.sh`, stabil Firefox release tag'lerini listeler ve seçimi güvenle `FIREFOX_COMMIT` dosyasına yazar.
- **CI**: GitHub Actions workflow’u otomatik olarak `FIREFOX_COMMIT` dosyasını günceller, böylece CI/CD süreciniz her zaman güncel bir Firefox sürümüyle çalışır.
- **Manuel override**: `FIREFOX_COMMIT` dosyasını elle değiştirerek belirli bir commit/tag’e zorlayabilirsiniz. Bu durumda workflow yine en yeni stable tag’i bulsa da dosyadaki değer önceliklidir.

---
### 4. İlgili dosyalar

- `scripts/setup-firefox.sh` – Firefox kaynağını `FIREFOX_COMMIT` ile checkout eder.
- `scripts/apply.sh` – Versiyon uyuşmazlığı varsa kullanıcıdan onay alır.
- `scripts/select-firefox-version.sh` – Stabil Firefox release tag listesinden seçim yapıp `FIREFOX_COMMIT` dosyasını günceller.
- `.github/workflows/check_firefox.yml` – Saatlik otomatik kontrol ve commit.
- `FIREFOX_COMMIT` – Projede tek kaynak olarak kullanılan Firefox sürüm etiketi.

---
**Bu belge, Hilal Browser projesinin sürüm yönetimini bütünsel olarak kapsar.**

[Back to docs index](../docs/WORKFLOW.md)
