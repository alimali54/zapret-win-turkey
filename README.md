# Zapret Windows Türkiye

Türk kullanıcılar için DPI (Deep Packet Inspection / Derin Paket İncelemesi) tabanlı internet sansürlerini ve kısıtlamalarını atlatmak amacıyla [zapret-win-bundle](https://github.com/bol-van/zapret-win-bundle) projesinin kullanımını kolaylaştıran bir AutoIt arayüzüdür.

## Ne yapıldı? (Düzenlemeler)

Bu depodaki orijinal kodu inceledik ve bazı sitelere erişimi engelleyen hataları giderdik:

### 1. DNS-over-HTTPS "fallback" sorunu (en önemli düzeltme)
Program sistem DNS'ini Cloudflare (1.1.1.1) yaparken DNS-over-HTTPS (DoH) sunucularını `AllowFallbackToUdp = $false` ile ayarlıyordu. ISS DoH trafiğini engellediğinde DNS sorunsuzca çalışmıyordu ve bazı siteler açılmıyordu.

**Düzeltme:** `AllowFallbackToUdp` değeri `$true` yapıldı. Artık DoH engellendiğinde sistem normal UDP DNS'e düşüyor, site erişimleri geri geliyor.

### 2. DNS "zehirlenme" tespiti çok sıcaktı
`CheckDnsPoisoningSilent()` fonksiyonu, tanınmayan bir DNS yanıtı geldiği anı otomatik olarak "DNS zehirlenmesi" olarak işaretleyip (`Return True`) butonları kilitliyordu. Bu da geçerli DNS ayarlarıyla bile programı çalıştıramamaya sebep oluyordu.

**Düzeltme:** Tanınmayan/beyaz-liste dışındaki yanıtlar artık otomatik zehirlenme sayılmıyor (`Return False`). Sadece bilinen TT zehirlenme IP'si (`195.175.254.2`) tespit edildiğinde uyarı veriliyor.

### 3. Blockcheck2 `.bak` yedekleme kilidi
Özel test domeni ayarı yapıldığında `blockcheck2.sh` yedekleniyordu; eskiden bir `.bak` dosyası kalıyorsa işlem tamamen durduruluyordu ve tekrar analiz yapılamıyordu.

**Düzeltme:** Eski `.bak` dosyası otomatik siliniyor ve analiz akışı normal şekilde devam ediyor.

## Özellikler

- **Çift motor:** Eski klasik Zapret (winws.exe) ve yeni LUA tabanlı Zapret2 (winws2.exe) desteği.
- **Blockcheck (ISS Analizi):** Hangi stratejinin çalıştığını otomatik olarak bulur.
- **Hazır strateji profilleri:** Turk Telekom, Superonline, Vodafone, Turksat Kablonet, Turkcell/Vodafone/Telekom Mobil gibi operatörlere özel hazır stratejiler.
- **Hostlist / Excludelist:** Sadece sansürlü siteleri filtreleyebilir; `com.tr`, `gov.tr`, `google.com`, `googleapis.com` varsayılan olarak dışarı tutulur.
- **DNSCrypt-proxy:** Şifreli DNS servisi kurma / kaldırma desteği.
- **Windows Servisi:** Bilgisayar açıldığında otomatik başlayan servis olarak kurulum.
- **Ağ paylaşımı:** Yerel ağdaki konsol (PlayStation, Xbox, Switch) ve akıllı TV ile paylaşım (go-pcap2socks veya V2Ray + MaraDNS).
- **Güncelleme kontrolü:** GitHub'dan yeni sürüm kontrolü.

## Kurulum

1. ZIP dosyasını **indirip bir klasöre çıkarın** (ZIP'in içinden doğrudan çalıştırmayın).
2. `zapret-win-turkey.au3` dosyasını AutoIt3 ile derleyin veya hazır `.exe`'yi kullanın.
3. Programı yönetici yetkisiyle çalıştırın.
4. İlk açılışta DNS zehirlenmesi tespit edilirseCloudflare DNS'yi ayarlamak için "Evet" deyin (veya YogaDNS / DNSCrypt-proxy kullanın).
5. "ISS Analizi (Blockcheck) Yap" düğmesiyle çalışan stratejiyi bulun veya hazır bir profil seçin.
6. "ZAPRET'İ BAŞLAT" düğmesiyle bağlantıyı açın.

## Sitelere giremiyorsanız (sorun giderme)

- Programı **ZIP'in içinden doğrudan çalıştırmayın**, önce klasöre çıkarın.
- DNS zehirlenmesi tespit edilirse Cloudflare DNS'yi kabul edin; yoksa YogaDNS + Google DoH ayarlayın.
- OOB/Syndata stratejileri hostlist filtresiyle çalışmaz; bu stratejiler sistem genelinde etkilidir.
- `goodbyedpi.exe` çalışıyorsa önce kapatın (çakışma uyarısı çıkar).
- Anti-Cheat yazılımları (Fortnite vb.) Zapret'i kapatabilir; bu durumda bilgisayarı yeniden başlatın.

## Teşekkür

- [@bol-van](https://github.com/bol-van) – Zapret ana motoru
- [@cagritaskn](https://github.com/cagritaskn) – Blockcheck otomatik analiz ilhamı
- [@DaniilSokolyuk](https://github.com/DaniilSokolyuk) – go-pcap2socks
- [@jedisct1](https://github.com/jedisct1) – dnscrypt-proxy
