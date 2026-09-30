# OGKS-Ozel_Gereksinim_Kayit_Sistemi-


## 📌 Projenin Amacı
Bu proje; özel gereksinimli (otizm, zihinsel ve fiziksel engel) bireylerin eğitim, sağlık, randevu, kriz ve ilaç takip süreçlerini tek bir çatı altında toplayan ilişkisel bir veri tabanı yönetim sistemidir. Aileler, uzmanlar ve doktorlar arasındaki veri dağınıklığını ortadan kaldırarak ortak bir karar destek mekanizması oluşturur.

## 🗄️ Veritabanı ve Teknik Altyapı
Proje, veri bütünlüğünü sağlamak amacıyla **3. Normal Form (3NF)** kurallarına göre normalize edilmiş **19 tabloluk** profesyonel bir Microsoft SQL Server (MSSQL) altyapısı üzerine kurulmuştur. 

Sistemde yer alan temel modüller şunlardır:

1. **Kullanıcı ve Rol Yönetimi (RBAC):** Veli, uzman, doktor ve yöneticilerin yetki bazlı güvenli erişimini sağlar.
2. **Birey ve Profil Yönetimi:** Bireyin temel bilgileri, engel grubu ve veli/kurum eşleşmelerini tutar.
3. **Eğitim ve Dijital BEP:** Bireyselleştirilmiş eğitim programı hedeflerini ve başarı puanlarını takip eder.
4. **Randevu ve Seans Yönetimi:** Uzman ile birey arasındaki seans planlamalarını, durum takibini ve çakışma önleme mantığını yönetir.
5. **Kriz ve Tetikleyici Günlüğü:** Kriz anlarını, şiddet derecelerini ve çevresel tetikleyicileri kayıt altına alır.
6. **İlaç ve Yan Etki Modülü:** Düzenli ilaç takibinin yanı sıra, olası reaksiyonların bakıcı tarafından girilip doktora raporlanmasını ve doktor geri bildirimlerinin saklanmasını sağlar.
7. **Materyal ve Cihaz Zimmet:** Tekerlekli sandalye, ortez veya özel eğitim materyallerinin zimmet takibini yapar.