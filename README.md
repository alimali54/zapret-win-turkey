<img width="402" height="442" alt="Ekran Alıntısı" src="https://github.com/user-attachments/assets/c2c18eb0-3013-405b-9238-491eaf58cc9e" />

# Zapret Türkiye Windows

Bu programın amacı Türk kullanıcılar için DPI yani Derin Paket İncelemesi (Deep Packet Inspection) sistemlerini atlatmak için geliştirilmiş olan [zapret-win-bundle](https://github.com/bol-van/zapret-win-bundle) projesinin kullanımını kolaylaştırmaktır.

## Programın Özellikleri

- **DNS Kontrolü:** Zapret çalışmadan önce DNS zehirlenmesi olup olmadığının kontrolünü yapar ve kullanıcıyı uyarır.
- **Akıllı Analiz:** Tek tuşla ISS'niz (İnternet Servis Sağlayıcı) için en uygun stratejiyi analiz eder (`blockcheck`).
- **Manuel Kullanım:** "Zapret'i Başlat" seçeneği ile programın içinden anlık kullanım imkanı sağlar. Program kapanınca Zapret süreci de otomatik olarak sonlandırılır.
- **Servis Desteği:** "Servis Olarak Yükle" butonu ile Windows Servisi olarak kullanma imkanı sunar. Bu modda program kapatılsa bile Zapret çalışmaya devam eder ve bilgisayar her açıldığında otomatik olarak başlar.
- **Autohostlist:** Engelli sitelerin tespiti otomatik yapılır ve sadece o siteler için çalıştırma imkanı sunar, böylece tüm trafiği yormaz.

## Teşekkürler

- **Zapret** projesinin ana motoru için [@bol-van](https://github.com/bol-van)'a,
- Otomatik blockcheck mantığı ve ilhamı için [splitwire-turkey](https://github.com/cagritaskn/splitwire-turkey) geliştiricisi [@cagritaskn](https://github.com/cagritaskn)'a
