#!/usr/bin/env python3
"""Generate localized App Store screenshots for all 39 supported languages."""

import os
import re

# Define translations for each language
# Format: (title1, desc1, title2, desc2, title3, desc3, title_ipad3, desc_ipad3)
TRANSLATIONS = {
    # English variants
    "en-US": (
        "WebView Tester", "Test WKWebView &amp; SafariVC instantly",
        "Built-in DevTools", "Console, Network, Storage and more",
        "Customize Settings", "Fine-tune options for precise testing",
        "WebView Capabilities", "Check API support and device info"
    ),
    "en-GB": (
        "WebView Tester", "Test WKWebView &amp; SafariVC instantly",
        "Built-in DevTools", "Console, Network, Storage and more",
        "Customise Settings", "Fine-tune options for precise testing",
        "WebView Capabilities", "Check API support and device info"
    ),
    "en-AU": (
        "WebView Tester", "Test WKWebView &amp; SafariVC instantly",
        "Built-in DevTools", "Console, Network, Storage and more",
        "Customise Settings", "Fine-tune options for precise testing",
        "WebView Capabilities", "Check API support and device info"
    ),
    "en-CA": (
        "WebView Tester", "Test WKWebView &amp; SafariVC instantly",
        "Built-in DevTools", "Console, Network, Storage and more",
        "Customize Settings", "Fine-tune options for precise testing",
        "WebView Capabilities", "Check API support and device info"
    ),

    # Korean (하세요체 - formal polite)
    "ko": (
        "WebView 테스터", "WKWebView와 SafariVC를 바로 테스트하세요",
        "내장 개발자 도구", "콘솔, 네트워크, 저장소 등을 확인하세요",
        "설정 커스터마이즈", "세밀한 테스트를 위해 옵션을 조정하세요",
        "WebView 기능", "API 지원과 기기 정보를 확인하세요"
    ),

    # Japanese (丁寧語 - polite form)
    "ja": (
        "WebView テスター", "WKWebViewとSafariVCをすぐにテストできます",
        "内蔵デベロッパーツール", "コンソール、ネットワーク、ストレージなどを確認できます",
        "設定をカスタマイズ", "細かいテストのためにオプションを調整できます",
        "WebView 機能", "APIサポートとデバイス情報を確認できます"
    ),

    # Chinese Simplified (敬语 - respectful language)
    "zh-Hans": (
        "WebView 测试工具", "立即测试 WKWebView 与 SafariVC",
        "内置开发者工具", "提供控制台、网络、存储等功能",
        "自定义设置", "可精确调整各项测试选项",
        "WebView 功能", "可查看 API 支持与设备信息"
    ),

    # Chinese Traditional (敬語 - respectful language)
    "zh-Hant": (
        "WebView 測試工具", "立即測試 WKWebView 與 SafariVC",
        "內建開發者工具", "提供控制台、網路、儲存等功能",
        "自訂設定", "可精確調整各項測試選項",
        "WebView 功能", "可查看 API 支援與裝置資訊"
    ),

    # German (Höflichkeitsform - Sie form)
    "de-DE": (
        "WebView Tester", "Testen Sie WKWebView &amp; SafariVC sofort",
        "Integrierte Entwicklertools", "Konsole, Netzwerk, Speicher und mehr",
        "Einstellungen anpassen", "Passen Sie die Optionen für präzise Tests an",
        "WebView Funktionen", "Prüfen Sie API-Unterstützung und Geräteinformationen"
    ),

    # French (France - vouvoiement)
    "fr-FR": (
        "Testeur WebView", "Testez WKWebView &amp; SafariVC instantanément",
        "Outils de développement intégrés", "Console, Réseau, Stockage et plus encore",
        "Personnaliser les réglages", "Ajustez les options pour des tests précis",
        "Fonctionnalités WebView", "Consultez le support API et les informations de l'appareil"
    ),

    # French (Canada - vouvoiement)
    "fr-CA": (
        "Testeur WebView", "Testez WKWebView &amp; SafariVC instantanément",
        "Outils de développement intégrés", "Console, Réseau, Stockage et plus encore",
        "Personnaliser les paramètres", "Ajustez les options pour des tests précis",
        "Fonctionnalités WebView", "Consultez le support API et les informations de l'appareil"
    ),

    # Spanish (Spain - usted form)
    "es-ES": (
        "Probador WebView", "Pruebe WKWebView y SafariVC al instante",
        "Herramientas de desarrollo integradas", "Consola, Red, Almacenamiento y más",
        "Personalizar ajustes", "Ajuste las opciones para pruebas precisas",
        "Funciones WebView", "Consulte el soporte API e información del dispositivo"
    ),

    # Spanish (Mexico - usted form)
    "es-MX": (
        "Probador WebView", "Pruebe WKWebView y SafariVC al instante",
        "Herramientas de desarrollo integradas", "Consola, Red, Almacenamiento y más",
        "Personalizar configuración", "Ajuste las opciones para pruebas precisas",
        "Funciones WebView", "Consulte el soporte API e información del dispositivo"
    ),

    # Portuguese (Brazil - você formal)
    "pt-BR": (
        "Testador WebView", "Teste WKWebView e SafariVC instantaneamente",
        "Ferramentas de desenvolvimento integradas", "Console, Rede, Armazenamento e mais",
        "Personalizar configurações", "Ajuste as opções para testes precisos",
        "Funcionalidades WebView", "Verifique o suporte de API e informações do dispositivo"
    ),

    # Portuguese (Portugal - formal)
    "pt-PT": (
        "Testador WebView", "Teste WKWebView e SafariVC instantaneamente",
        "Ferramentas de desenvolvimento integradas", "Consola, Rede, Armazenamento e mais",
        "Personalizar definições", "Ajuste as opções para testes precisos",
        "Funcionalidades WebView", "Verifique o suporte de API e informações do dispositivo"
    ),

    # Italian (Lei form - formal)
    "it": (
        "Tester WebView", "Testi WKWebView e SafariVC all'istante",
        "Strumenti di sviluppo integrati", "Console, Rete, Archiviazione e altro",
        "Personalizza impostazioni", "Regoli le opzioni per test precisi",
        "Funzionalità WebView", "Verifichi il supporto API e le info del dispositivo"
    ),

    # Dutch (U form - formal)
    "nl-NL": (
        "WebView Tester", "Test WKWebView &amp; SafariVC direct",
        "Ingebouwde ontwikkelaarstools", "Console, Netwerk, Opslag en meer",
        "Instellingen aanpassen", "Pas de opties aan voor nauwkeurig testen",
        "WebView Mogelijkheden", "Bekijk API-ondersteuning en apparaatinformatie"
    ),

    # Russian (Вы form - formal)
    "ru": (
        "Тестер WebView", "Тестируйте WKWebView и SafariVC мгновенно",
        "Встроенные инструменты разработчика", "Консоль, Сеть, Хранилище и многое другое",
        "Настройка параметров", "Настройте параметры для точного тестирования",
        "Возможности WebView", "Проверьте поддержку API и информацию об устройстве"
    ),

    # Ukrainian (Ви form - formal)
    "uk": (
        "Тестер WebView", "Тестуйте WKWebView та SafariVC миттєво",
        "Вбудовані інструменти розробника", "Консоль, Мережа, Сховище та багато іншого",
        "Налаштування параметрів", "Налаштуйте параметри для точного тестування",
        "Можливості WebView", "Перевірте підтримку API та інформацію про пристрій"
    ),

    # Polish (Pan/Pani form - formal)
    "pl": (
        "Tester WebView", "Proszę przetestować WKWebView i SafariVC natychmiast",
        "Wbudowane narzędzia deweloperskie", "Konsola, Sieć, Pamięć i wiele więcej",
        "Dostosuj ustawienia", "Proszę dostosować opcje dla precyzyjnych testów",
        "Funkcje WebView", "Proszę sprawdzić obsługę API i informacje o urządzeniu"
    ),

    # Turkish (formal imperative with -iniz)
    "tr": (
        "WebView Test Aracı", "WKWebView ve SafariVC'yi hemen test ediniz",
        "Yerleşik Geliştirici Araçları", "Konsol, Ağ, Depolama ve daha fazlası",
        "Ayarları Özelleştirin", "Hassas test için seçenekleri ayarlayınız",
        "WebView Özellikleri", "API desteğini ve cihaz bilgisini kontrol ediniz"
    ),

    # Arabic (formal with من فضلك)
    "ar-SA": (
        "مختبر WebView", "اختبر WKWebView و SafariVC فوراً",
        "أدوات المطور المدمجة", "وحدة التحكم والشبكة والتخزين والمزيد",
        "تخصيص الإعدادات", "اضبط الخيارات للاختبار الدقيق",
        "إمكانيات WebView", "تحقق من دعم API ومعلومات الجهاز"
    ),

    # Hebrew (formal)
    "he": (
        "בודק WebView", "בדקו WKWebView ו-SafariVC מיידית",
        "כלי פיתוח מובנים", "קונסול, רשת, אחסון ועוד",
        "התאמת הגדרות", "כוונו את האפשרויות לבדיקות מדויקות",
        "יכולות WebView", "בדקו את תמיכת API ומידע על המכשיר"
    ),

    # Hindi (आप form - formal)
    "hi": (
        "WebView टेस्टर", "WKWebView और SafariVC को तुरंत टेस्ट करें",
        "बिल्ट-इन डेवटूल्स", "कंसोल, नेटवर्क, स्टोरेज और भी बहुत कुछ",
        "सेटिंग्स अनुकूलित करें", "सटीक परीक्षण के लिए विकल्पों को समायोजित करें",
        "WebView क्षमताएं", "API सपोर्ट और डिवाइस जानकारी देखें"
    ),

    # Thai (ครับ/ค่ะ polite particles)
    "th": (
        "WebView Tester", "ทดสอบ WKWebView และ SafariVC ได้ทันทีครับ",
        "เครื่องมือนักพัฒนาในตัว", "คอนโซล เครือข่าย พื้นที่จัดเก็บ และอื่นๆ",
        "ปรับแต่งการตั้งค่า", "ปรับตัวเลือกสำหรับการทดสอบที่แม่นยำครับ",
        "ความสามารถ WebView", "ตรวจสอบการรองรับ API และข้อมูลอุปกรณ์ครับ"
    ),

    # Vietnamese (formal with Quý vị)
    "vi": (
        "Công cụ thử nghiệm WebView", "Thử nghiệm WKWebView &amp; SafariVC ngay lập tức",
        "Công cụ phát triển tích hợp", "Console, Mạng, Lưu trữ và nhiều tính năng khác",
        "Tùy chỉnh cài đặt", "Điều chỉnh các tùy chọn để thử nghiệm chính xác",
        "Khả năng WebView", "Kiểm tra hỗ trợ API và thông tin thiết bị"
    ),

    # Indonesian (formal with Anda)
    "id": (
        "Penguji WebView", "Uji WKWebView &amp; SafariVC secara instan",
        "Alat Pengembang Bawaan", "Console, Jaringan, Penyimpanan, dan lainnya",
        "Sesuaikan Pengaturan", "Sesuaikan opsi untuk pengujian yang presisi",
        "Kemampuan WebView", "Periksa dukungan API dan informasi perangkat"
    ),

    # Malay (formal)
    "ms": (
        "Penguji WebView", "Uji WKWebView &amp; SafariVC dengan serta-merta",
        "Alat Pembangun Terbina Dalam", "Konsol, Rangkaian, Storan dan banyak lagi",
        "Sesuaikan Tetapan", "Laraskan pilihan untuk ujian yang tepat",
        "Keupayaan WebView", "Semak sokongan API dan maklumat peranti"
    ),

    # Danish (formal De/Dem)
    "da": (
        "WebView Tester", "Test WKWebView og SafariVC øjeblikkeligt",
        "Indbyggede udviklerværktøjer", "Konsol, Netværk, Lagring og meget mere",
        "Tilpas indstillinger", "Juster indstillingerne for præcis testning",
        "WebView-funktioner", "Se API-understøttelse og enhedsoplysninger"
    ),

    # Swedish (formal ni/Ni)
    "sv": (
        "WebView Testare", "Testa WKWebView och SafariVC omedelbart",
        "Inbyggda utvecklarverktyg", "Konsol, Nätverk, Lagring och mycket mer",
        "Anpassa inställningar", "Justera alternativen för exakt testning",
        "WebView Funktioner", "Se API-stöd och enhetsinformation"
    ),

    # Norwegian (formal De/Dem)
    "no": (
        "WebView Tester", "Test WKWebView og SafariVC umiddelbart",
        "Innebygde utviklerverktøy", "Konsoll, Nettverk, Lagring og mye mer",
        "Tilpass innstillinger", "Juster alternativene for presis testing",
        "WebView Funksjoner", "Se API-støtte og enhetsinformasjon"
    ),

    # Finnish (formal Te/Teitä)
    "fi": (
        "WebView Testaaja", "Testatkaa WKWebView ja SafariVC heti",
        "Sisäänrakennetut kehitystyökalut", "Konsoli, Verkko, Tallennustila ja paljon muuta",
        "Mukauta asetuksia", "Säätäkää vaihtoehdot tarkkaan testaukseen",
        "WebView-ominaisuudet", "Tarkistakaa API-tuki ja laitetiedot"
    ),

    # Czech (Vy form - formal)
    "cs": (
        "WebView Tester", "Otestujte WKWebView a SafariVC okamžitě",
        "Vestavěné vývojářské nástroje", "Konzole, Síť, Úložiště a mnoho dalšího",
        "Přizpůsobit nastavení", "Upravte možnosti pro přesné testování",
        "Funkce WebView", "Zkontrolujte podporu API a informace o zařízení"
    ),

    # Slovak (Vy form - formal)
    "sk": (
        "WebView Tester", "Otestujte WKWebView a SafariVC okamžite",
        "Vstavané vývojárske nástroje", "Konzola, Sieť, Úložisko a oveľa viac",
        "Prispôsobiť nastavenia", "Upravte možnosti pre presné testovanie",
        "Funkcie WebView", "Skontrolujte podporu API a informácie o zariadení"
    ),

    # Hungarian (Ön form - formal)
    "hu": (
        "WebView Tesztelő", "Tesztelje a WKWebView-t és SafariVC-t azonnal",
        "Beépített fejlesztőeszközök", "Konzol, Hálózat, Tárhely és még sok más",
        "Beállítások testreszabása", "Állítsa be az opciókat a pontos teszteléshez",
        "WebView Képességek", "Ellenőrizze az API támogatást és az eszközinformációt"
    ),

    # Romanian (Dumneavoastră form - formal)
    "ro": (
        "Tester WebView", "Testați WKWebView și SafariVC instantaneu",
        "Instrumente de dezvoltator integrate", "Consolă, Rețea, Stocare și multe altele",
        "Personalizare setări", "Ajustați opțiunile pentru testare precisă",
        "Funcționalități WebView", "Verificați suportul API și informațiile dispozitivului"
    ),

    # Greek (εσείς form - formal plural)
    "el": (
        "Δοκιμαστής WebView", "Δοκιμάστε WKWebView &amp; SafariVC αμέσως",
        "Ενσωματωμένα εργαλεία ανάπτυξης", "Κονσόλα, Δίκτυο, Αποθήκευση και πολλά άλλα",
        "Προσαρμογή ρυθμίσεων", "Προσαρμόστε τις επιλογές για ακριβείς δοκιμές",
        "Δυνατότητες WebView", "Ελέγξτε την υποστήριξη API και τις πληροφορίες συσκευής"
    ),

    # Croatian (Vi form - formal)
    "hr": (
        "WebView Tester", "Testirajte WKWebView i SafariVC odmah",
        "Ugrađeni razvojni alati", "Konzola, Mreža, Pohrana i još mnogo toga",
        "Prilagodite postavke", "Podesite opcije za precizno testiranje",
        "WebView Mogućnosti", "Provjerite podršku za API i informacije o uređaju"
    ),

    # Catalan (vostè form - formal)
    "ca": (
        "Provador WebView", "Proveu WKWebView i SafariVC a l'instant",
        "Eines de desenvolupador integrades", "Consola, Xarxa, Emmagatzematge i molt més",
        "Personalitzar configuració", "Ajusteu les opcions per a proves precises",
        "Funcionalitats WebView", "Consulteu el suport d'API i la informació del dispositiu"
    ),
}

def escape_for_regex(text):
    """Escape special regex characters."""
    return re.escape(text)


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    # Original English texts to replace
    originals = {
        "title1": "WebView Tester",
        "desc1": "Test WKWebView &amp; SafariVC instantly",
        "title2": "Built-in DevTools",
        "desc2": "Console, Network, Storage and more",
        "title3": "Customize Settings",
        "desc3": "Fine-tune options for precise testing",
        "title_ipad3": "WebView Capabilities",
        "desc_ipad3": "Check API support and device info",
    }

    print(f"Generating localized screenshots for {len(TRANSLATIONS)} languages...")

    for lang, texts in TRANSLATIONS.items():
        print(f"Processing: {lang}")

        title1, desc1, title2, desc2, title3, desc3, title_ipad3, desc_ipad3 = texts

        # Create language directory
        os.makedirs(lang, exist_ok=True)

        # iPhone screenshots (1.svg, 2.svg, 3.svg)
        for i in [1, 2, 3]:
            src_file = f"en/{i}.svg"
            dst_file = f"{lang}/{i}.svg"

            with open(src_file, "r", encoding="utf-8") as f:
                content = f.read()

            # Replace texts based on which screenshot
            if i == 1:
                content = content.replace(f">{originals['title1']}<", f">{title1}<")
                content = content.replace(f">{originals['desc1']}<", f">{desc1}<")
            elif i == 2:
                content = content.replace(f">{originals['title2']}<", f">{title2}<")
                content = content.replace(f">{originals['desc2']}<", f">{desc2}<")
            elif i == 3:
                content = content.replace(f">{originals['title3']}<", f">{title3}<")
                content = content.replace(f">{originals['desc3']}<", f">{desc3}<")

            with open(dst_file, "w", encoding="utf-8") as f:
                f.write(content)

        # iPad screenshots (ipad-1.svg, ipad-2.svg, ipad-3.svg)
        for i in [1, 2, 3]:
            src_file = f"en/ipad-{i}.svg"
            dst_file = f"{lang}/ipad-{i}.svg"

            with open(src_file, "r", encoding="utf-8") as f:
                content = f.read()

            # Replace texts based on which screenshot
            if i == 1:
                content = content.replace(f">{originals['title1']}<", f">{title1}<")
                content = content.replace(f">{originals['desc1']}<", f">{desc1}<")
            elif i == 2:
                content = content.replace(f">{originals['title2']}<", f">{title2}<")
                content = content.replace(f">{originals['desc2']}<", f">{desc2}<")
            elif i == 3:
                content = content.replace(f">{originals['title_ipad3']}<", f">{title_ipad3}<")
                content = content.replace(f">{originals['desc_ipad3']}<", f">{desc_ipad3}<")

            with open(dst_file, "w", encoding="utf-8") as f:
                f.write(content)

    print(f"\nDone! Generated screenshots for {len(TRANSLATIONS)} languages.")
    print("\nLanguages generated:")
    for lang in sorted(TRANSLATIONS.keys()):
        print(f"  - {lang}")


if __name__ == "__main__":
    main()
