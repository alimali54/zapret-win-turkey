<img width="402" height="567" alt="image" src="https://github.com/user-attachments/assets/5c50ee40-ce9e-4ddd-9a08-31bf943cd75c" />


# Zapret Windows Türkiye

Bu programın amacı, Türk kullanıcılar için DPI (Deep Packet Inspection / Derin Paket İncelemesi) tabanlı internet sansürlerini ve kısıtlamalarını atlatmak amacıyla geliştirilmiş olan [zapret-win-bundle](https://github.com/bol-van/zapret-win-bundle) projesinin kullanımını kolaylaştırmaktır.

## Programın Özellikleri

- **DNS Kontrolü:** ISS tarafından DNS'inize müdahale ediliyorsa tespiti yapılır. DNS'i sağlama almak için YogaDNS kurmanızı ve Google DoH ayarlamanızı öneririm.
- **Blockcheck:** ISS'niz için çalışan stratejiyi bulmak için blockcheck yapabilirsiniz.
- **Hazır Stratejiler:** Bulabildiğim bazı hazır stratejileri programa ekledim, blockcheck yapmaya gerek kalmadan deneyebilirsiniz.
- **Çoklu Motor Desteği (Multi-Engine):** Hem eski klasik Zapret motorunu hem de yeni nesil LUA tabanlı gelişmiş Zapret2 motorunu entegre olarak barındırır.
- **Manuel Kullanım:** "Zapret'i Başlat" seçeneği ile program içinden anlık kullanım sağlar. Program kapatıldığında tüm süreçler temizlenir.
- **Servis Desteği:** "Servis Olarak Yükle" butonu ile Windows Servisi olarak kurma imkanı sunar. Bilgisayar her açıldığında otomatik başlar. Bu programın açılmasına gerek kalmaz.
- **Hostlist Desteği:** Sadece sansürlü siteleri listeye ekleyerek (otomatik veya manuel) filtreleme yapar; normal internet trafiğinizi kesinlikle yormaz.
- **Excludelist Desteği:** Zapret'in aktif olmasını istemediğiniz domain'leri excludelist.txt dosyasına yazabilirsiniz. Varsayılan olarak com.tr ve gov.tr uzantılı siteler eklenmiştir.
- **Ağdaki Cihazlarla Paylaş (v3.5.0):** `go-pcap2socks` entegrasyonu sayesinde, bilgisayarınızda çalışan Zapret motorunu yerel ağdaki diğer cihazlarınızla (PlayStation, Xbox, Nintendo Switch, Akıllı TV vb.) paylaşmanızı sağlar. Konsollarda Discord ve Roblox gibi erişim engellerini aşmanın en kararlı yoludur.

## Yerel Ağ Paylaşımı (Konsol / Diğer Cihazlar) Kurulumu

> [!CAUTION]
> Wi-Fi ile kullanırsa önemli ölçüde hız düşüşü yaşanabilir.
> 
> Hız düşüşü yaşarsanız bilgisayarı modem/router'a kablo ile bağlayın. 

"Ağdaki Cihazlarla Paylaş" özelliğini kullanabilmek için bilgisayarınızda **[Npcap](https://npcap.com/)** sürücüsünün kurulu olması gerekmektedir. 

Özelliği aktifleştirdikten sonra, ağdaki diğer cihazınızın (Örn: PlayStation/Xbox) **Manuel Ağ Ayarları** kısmına girerek aşağıdaki yapılandırmayı uygulamanız yeterlidir:

- **IP Adresi:** `172.24.2.10` ile `172.24.2.255` arasında boş bir IP (Örn: `172.24.2.50`)
- **Alt Ağ Maskesi (Subnet Mask):** `255.255.0.0`
- **Varsayılan Ağ Geçidi (Gateway):** `172.24.2.1`
- **Birincil DNS (Primary DNS):** `1.1.1.1`
- **İkincil DNS (Secondary DNS):** `8.8.8.8`

## Çakışma Önleme

Program, arka planda çalışabilecek diğer DPI atlatma araçlarıyla (`GoodbyeDPI` vb.) veya eski `WinDivert` sürücü kalıntılarıyla çakışmaları otomatik olarak tespit eder, temizler ve güvenli bir açılış sağlar.

## Teşekkürler

- **Zapret** projesinin ana motoru için [@bol-van](https://github.com/bol-van)'a,
- Otomatik blockcheck mantığı ve ilhamı için [splitwire-turkey](https://github.com/cagritaskn/splitwire-turkey) geliştiricisi [@cagritaskn](https://github.com/cagritaskn)'a,
- [go-pcap2socks](https://github.com/DaniilSokolyuk/go-pcap2socks) projesinin geliştiricisi [@DaniilSokolyuk](https://github.com/DaniilSokolyuk)'a teşekkür ederiz.
