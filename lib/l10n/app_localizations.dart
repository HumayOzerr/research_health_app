import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('de'),
    Locale('tr'),
    Locale('es'),
    Locale('it'),
    Locale('fr'),
    Locale('zh'),
    Locale('ja'),
    Locale('ko'),
    Locale('ar'),
    Locale('ru'),
  ];

  String get _lang => locale.languageCode;

  // ── App ──────────────────────────────────────────────────────────────────
  String get appTitle => _t(en: 'Health Research Study', de: 'Gesundheitsstudie', tr: 'Sağlık Araştırması', es: 'Estudio de Salud', it: 'Studio sulla Salute', fr: 'Étude de Santé', zh: '健康研究', ja: '健康研究', ko: '건강 연구', ar: 'دراسة الصحة', ru: 'Исследование Здоровья');

  // ── Consent ───────────────────────────────────────────────────────────────
  String get consentTitle => _t(en: 'Informed Consent', de: 'Einverständniserklärung', tr: 'Bilgilendirilmiş Onam', es: 'Consentimiento Informado', it: 'Consenso Informato', fr: 'Consentement Éclairé', zh: '知情同意书', ja: '同意書', ko: '동의서', ar: 'موافقة مستنيرة', ru: 'Информированное Согласие');
  String get consentSubtitle => 'ETH Zurich — Spinal Cord Injury & Artificial Intelligence Lab';

  String get consentPurposeTitle => _t(en: 'Purpose of this study', de: 'Zweck der Studie', tr: 'Çalışmanın amacı', es: 'Propósito del estudio', it: 'Scopo dello studio', fr: 'Objectif de l\'étude', zh: '研究目的', ja: '研究の目的', ko: '연구 목적', ar: 'الغرض من الدراسة', ru: 'Цель исследования');
  String get consentPurposeBody => _t(
    en: 'This app is a prototype for a research tool that collects self-reported wellbeing data alongside passively sensed health metrics. The goal is to explore how smartphone-based data can support biomedical and clinical research.',
    de: 'Diese App ist ein Prototyp für ein Forschungswerkzeug, das selbst berichtete Wohlbefindensdaten zusammen mit passiv erfassten Gesundheitsmetriken sammelt. Ziel ist es zu erforschen, wie smartphone-basierte Daten die biomedizinische und klinische Forschung unterstützen können.',
    tr: 'Bu uygulama, pasif olarak algılanan sağlık ölçümleriyle birlikte öz bildirilen iyilik hali verilerini toplayan bir araştırma aracının prototipidir. Amaç, akıllı telefon tabanlı verilerin biyomedikal ve klinik araştırmaları nasıl destekleyebileceğini keşfetmektir.',
    es: 'Esta aplicación es un prototipo de herramienta de investigación que recopila datos de bienestar autoinformados junto con métricas de salud capturadas pasivamente. El objetivo es explorar cómo los datos basados en smartphone pueden apoyar la investigación biomédica y clínica.',
    it: 'Questa app è un prototipo di strumento di ricerca che raccoglie dati di benessere autodichiarati insieme a metriche di salute rilevate passivamente. L\'obiettivo è esplorare come i dati basati su smartphone possano supportare la ricerca biomedica e clinica.',
    fr: 'Cette application est un prototype d\'outil de recherche qui collecte des données de bien-être auto-déclarées avec des métriques de santé captées passivement. L\'objectif est d\'explorer comment les données smartphone peuvent soutenir la recherche biomédicale et clinique.',
    zh: '本应用是一款研究工具原型，用于收集自我报告的健康数据和被动感知的健康指标。目标是探索基于智能手机的数据如何支持生物医学和临床研究。',
    ja: 'このアプリは、自己申告の健康データと受動的に取得した健康指標を収集する研究ツールのプロトタイプです。スマートフォンベースのデータが生物医学・臨床研究をどのように支援できるかを探ることを目的としています。',
    ko: '이 앱은 자가 보고 웰빙 데이터와 수동으로 감지된 건강 지표를 수집하는 연구 도구의 프로토타입입니다. 스마트폰 기반 데이터가 생의학 및 임상 연구를 어떻게 지원할 수 있는지 탐구하는 것이 목표입니다.',
    ar: 'هذا التطبيق نموذج أولي لأداة بحثية تجمع بيانات الرفاهية الذاتية جنبًا إلى جنب مع مقاييس الصحة المرصودة بشكل سلبي. الهدف هو استكشاف كيف يمكن للبيانات القائمة على الهاتف الذكي دعم الأبحاث الطبية والسريرية.',
    ru: 'Это приложение является прототипом исследовательского инструмента, собирающего самооценённые данные о благополучии вместе с пассивно отслеживаемыми показателями здоровья. Цель — изучить, как данные со смартфона могут поддержать биомедицинские и клинические исследования.',
  );

  String get consentDataTitle => _t(en: 'What data will be collected', de: 'Welche Daten werden erhoben', tr: 'Hangi veriler toplanacak', es: 'Qué datos se recopilarán', it: 'Quali dati saranno raccolti', fr: 'Données collectées', zh: '将收集哪些数据', ja: '収集されるデータ', ko: '수집될 데이터', ar: 'البيانات التي سيتم جمعها', ru: 'Какие данные будут собраны');
  String get consentDataBody => _t(
    en: 'With your consent, this app will collect:\n\n• Your participant ID and age range\n• A wellbeing self-rating (1–5 scale) and optional comment\n• Step count (today)\n• Heart rate (most recent reading)\n• Sleep duration (last night)\n• Active energy burned (today)',
    de: 'Mit Ihrer Einwilligung erhebt diese App:\n\n• Ihre Teilnehmer-ID und Altersgruppe\n• Eine Wohlbefindens-Selbstbewertung (Skala 1–5) und optionalen Kommentar\n• Schrittanzahl (heute)\n• Herzfrequenz (aktuellste Messung)\n• Schlafdauer (letzte Nacht)\n• Verbrannte aktive Energie (heute)',
    tr: 'Onayınızla bu uygulama şunları toplayacak:\n\n• Katılımcı kimliğiniz ve yaş aralığınız\n• İyilik hali öz değerlendirmesi (1–5 ölçeği) ve isteğe bağlı yorum\n• Adım sayısı (bugün)\n• Kalp hızı (en son okuma)\n• Uyku süresi (dün gece)\n• Yakılan aktif enerji (bugün)',
    es: 'Con su consentimiento, esta app recopilará:\n\n• Su ID de participante y rango de edad\n• Una autoevaluación de bienestar (escala 1–5) y comentario opcional\n• Recuento de pasos (hoy)\n• Frecuencia cardíaca (lectura más reciente)\n• Duración del sueño (anoche)\n• Energía activa quemada (hoy)',
    it: 'Con il tuo consenso, questa app raccoglierà:\n\n• Il tuo ID partecipante e fascia d\'età\n• Una valutazione del benessere (scala 1–5) e commento opzionale\n• Conteggio passi (oggi)\n• Frequenza cardiaca (lettura più recente)\n• Durata del sonno (scorsa notte)\n• Energia attiva bruciata (oggi)',
    fr: 'Avec votre consentement, cette application collectera:\n\n• Votre identifiant participant et tranche d\'âge\n• Une auto-évaluation du bien-être (échelle 1–5) et un commentaire optionnel\n• Nombre de pas (aujourd\'hui)\n• Fréquence cardiaque (dernière mesure)\n• Durée du sommeil (nuit dernière)\n• Énergie active brûlée (aujourd\'hui)',
    zh: '经您同意，本应用将收集：\n\n• 您的参与者ID和年龄段\n• 健康自我评分（1–5分）和可选评论\n• 步数（今天）\n• 心率（最新读数）\n• 睡眠时长（昨晚）\n• 主动消耗能量（今天）',
    ja: '同意いただいた場合、このアプリは以下を収集します：\n\n• 参加者IDと年齢層\n• 健康度自己評価（1–5スケール）とオプションコメント\n• 歩数（本日）\n• 心拍数（最新データ）\n• 睡眠時間（昨夜）\n• 消費アクティブエネルギー（本日）',
    ko: '동의하시면 이 앱이 다음을 수집합니다:\n\n• 참가자 ID 및 연령대\n• 웰빙 자기 평가(1–5 척도) 및 선택적 의견\n• 걸음 수(오늘)\n• 심박수(최근 측정값)\n• 수면 시간(어젯밤)\n• 소모된 활동 에너지(오늘)',
    ar: 'بموافقتك، سيجمع هذا التطبيق:\n\n• معرف المشارك ونطاق العمر\n• تقييم ذاتي للرفاهية (مقياس 1–5) وتعليق اختياري\n• عدد الخطوات (اليوم)\n• معدل ضربات القلب (أحدث قراءة)\n• مدة النوم (الليلة الماضية)\n• الطاقة النشطة المحترقة (اليوم)',
    ru: 'С вашего согласия приложение соберёт:\n\n• Ваш ID участника и возрастной диапазон\n• Самооценку самочувствия (шкала 1–5) и необязательный комментарий\n• Количество шагов (сегодня)\n• Частоту пульса (последнее измерение)\n• Продолжительность сна (прошлой ночью)\n• Активно сожжённую энергию (сегодня)',
  );

  String get consentUsageTitle => _t(en: 'How your data will be used', de: 'Verwendung Ihrer Daten', tr: 'Verileriniz nasıl kullanılacak', es: 'Cómo se usarán sus datos', it: 'Come verranno usati i tuoi dati', fr: 'Utilisation de vos données', zh: '您的数据将如何使用', ja: 'データの利用方法', ko: '데이터 사용 방법', ar: 'كيف سيتم استخدام بياناتك', ru: 'Как будут использоваться ваши данные');
  String get consentUsageBody => _t(
    en: 'Your data will be transmitted to a research server and associated only with your participant ID — not your name or contact details. It will be used solely for research purposes within this study.',
    de: 'Ihre Daten werden an einen Forschungsserver übertragen und ausschließlich mit Ihrer Teilnehmer-ID verknüpft — nicht mit Ihrem Namen oder Kontaktdaten. Sie werden ausschließlich für Forschungszwecke dieser Studie verwendet.',
    tr: 'Verileriniz bir araştırma sunucusuna iletilecek ve yalnızca katılımcı kimliğinizle ilişkilendirilecektir — adınız veya iletişim bilgilerinizle değil. Yalnızca bu çalışma kapsamındaki araştırma amaçları için kullanılacaktır.',
    es: 'Sus datos se transmitirán a un servidor de investigación y se asociarán únicamente con su ID de participante, no con su nombre ni datos de contacto. Se utilizarán exclusivamente con fines de investigación dentro de este estudio.',
    it: 'I tuoi dati saranno trasmessi a un server di ricerca e associati solo al tuo ID partecipante — non al tuo nome o ai tuoi dati di contatto. Saranno utilizzati esclusivamente per scopi di ricerca all\'interno di questo studio.',
    fr: 'Vos données seront transmises à un serveur de recherche et associées uniquement à votre identifiant participant — pas à votre nom ou coordonnées. Elles seront utilisées uniquement à des fins de recherche dans le cadre de cette étude.',
    zh: '您的数据将传输到研究服务器，仅与您的参与者ID关联——不涉及您的姓名或联系方式。数据仅用于本研究的研究目的。',
    ja: 'データは研究サーバーに送信され、参加者IDのみに紐付けられます（氏名や連絡先は使用しません）。本研究の研究目的にのみ使用されます。',
    ko: '데이터는 연구 서버로 전송되며 참가자 ID에만 연결됩니다(이름이나 연락처는 포함되지 않음). 이 연구의 연구 목적으로만 사용됩니다.',
    ar: 'ستُرسل بياناتك إلى خادم بحثي وستُربط فقط بمعرف المشارك الخاص بك — ليس باسمك أو تفاصيل الاتصال. ستُستخدم فقط لأغراض البحث ضمن هذه الدراسة.',
    ru: 'Ваши данные будут переданы на исследовательский сервер и связаны только с вашим ID участника — без имени или контактных данных. Они будут использоваться исключительно в исследовательских целях этого исследования.',
  );

  String get consentPermissionsTitle => _t(en: 'Health data permissions', de: 'Gesundheitsdaten-Berechtigungen', tr: 'Sağlık verisi izinleri', es: 'Permisos de datos de salud', it: 'Autorizzazioni dati sanitari', fr: 'Autorisations de données de santé', zh: '健康数据权限', ja: '健康データの許可', ko: '건강 데이터 권한', ar: 'أذونات بيانات الصحة', ru: 'Разрешения на данные о здоровье');
  String get consentPermissionsBody => _t(
    en: 'The app will request access to your device\'s health data (Apple HealthKit on iOS, Health Connect on Android). You can review exactly which data is being submitted before it is sent. You may deny any permission without affecting the rest of the app.',
    de: 'Die App fordert Zugriff auf die Gesundheitsdaten Ihres Geräts an (Apple HealthKit auf iOS, Health Connect auf Android). Sie können genau prüfen, welche Daten gesendet werden, bevor sie übermittelt werden. Sie können jede Berechtigung ablehnen, ohne die übrige Funktionalität der App zu beeinträchtigen.',
    tr: 'Uygulama, cihazınızın sağlık verilerine erişim isteyecektir (iOS\'ta Apple HealthKit, Android\'de Health Connect). Gönderilmeden önce tam olarak hangi verilerin iletildiğini inceleyebilirsiniz. Herhangi bir izni, uygulamanın geri kalanını etkilemeden reddedebilirsiniz.',
    es: 'La aplicación solicitará acceso a los datos de salud de su dispositivo (Apple HealthKit en iOS, Health Connect en Android). Puede revisar exactamente qué datos se enviarán antes de que sean transmitidos. Puede denegar cualquier permiso sin afectar el resto de la aplicación.',
    it: 'L\'app richiederà l\'accesso ai dati sanitari del tuo dispositivo (Apple HealthKit su iOS, Health Connect su Android). Puoi esaminare esattamente quali dati vengono inviati prima che vengano trasmessi. Puoi negare qualsiasi autorizzazione senza influire sul resto dell\'app.',
    fr: 'L\'application demandera l\'accès aux données de santé de votre appareil (Apple HealthKit sur iOS, Health Connect sur Android). Vous pouvez vérifier exactement quelles données sont soumises avant leur envoi. Vous pouvez refuser toute autorisation sans affecter le reste de l\'application.',
    zh: '应用将请求访问您设备的健康数据（iOS上的Apple HealthKit，Android上的Health Connect）。您可以在提交前查看将发送的确切数据。您可以拒绝任何权限，不会影响应用的其他功能。',
    ja: 'アプリはデバイスの健康データへのアクセスを要求します（iOSではApple HealthKit、AndroidではHealth Connect）。送信前に正確にどのデータが提出されるかを確認できます。アプリの他の機能に影響を与えることなく、いずれの許可も拒否できます。',
    ko: '앱은 기기의 건강 데이터에 대한 액세스를 요청합니다(iOS에서 Apple HealthKit, Android에서 Health Connect). 전송 전에 제출될 데이터를 정확히 검토할 수 있습니다. 앱의 나머지 기능에 영향을 주지 않고 권한을 거부할 수 있습니다.',
    ar: 'سيطلب التطبيق الوصول إلى بيانات الصحة في جهازك (Apple HealthKit على iOS، Health Connect على Android). يمكنك مراجعة البيانات التي ستُرسل بالضبط قبل إرسالها. يمكنك رفض أي إذن دون التأثير على بقية التطبيق.',
    ru: 'Приложение запросит доступ к данным о здоровье вашего устройства (Apple HealthKit на iOS, Health Connect на Android). Вы можете просмотреть, какие именно данные будут отправлены, до их передачи. Вы можете отклонить любое разрешение без влияния на остальные функции приложения.',
  );

  String get consentRightsTitle => _t(en: 'Your rights', de: 'Ihre Rechte', tr: 'Haklarınız', es: 'Sus derechos', it: 'I tuoi diritti', fr: 'Vos droits', zh: '您的权利', ja: 'あなたの権利', ko: '귀하의 권리', ar: 'حقوقك', ru: 'Ваши права');
  String get consentRightsBody => _t(
    en: '• Participation is entirely voluntary.\n• You may withdraw at any time by closing the app.\n• You will be able to review all collected data before submission.\n• You may contact the research team with any questions.',
    de: '• Die Teilnahme ist vollständig freiwillig.\n• Sie können jederzeit durch Schließen der App aussteigen.\n• Sie können alle gesammelten Daten vor der Übermittlung einsehen.\n• Bei Fragen können Sie das Forschungsteam kontaktieren.',
    tr: '• Katılım tamamen gönüllülük esasına dayanmaktadır.\n• Uygulamayı kapatarak istediğiniz zaman çekilebilirsiniz.\n• Gönderimden önce tüm toplanan verileri inceleyebileceksiniz.\n• Herhangi bir sorunuz için araştırma ekibiyle iletişime geçebilirsiniz.',
    es: '• La participación es completamente voluntaria.\n• Puede retirarse en cualquier momento cerrando la aplicación.\n• Podrá revisar todos los datos recopilados antes de enviarlos.\n• Puede contactar al equipo de investigación con cualquier pregunta.',
    it: '• La partecipazione è completamente volontaria.\n• Puoi ritirarti in qualsiasi momento chiudendo l\'app.\n• Potrai esaminare tutti i dati raccolti prima dell\'invio.\n• Puoi contattare il team di ricerca per qualsiasi domanda.',
    fr: '• La participation est entièrement volontaire.\n• Vous pouvez vous retirer à tout moment en fermant l\'application.\n• Vous pourrez examiner toutes les données collectées avant soumission.\n• Vous pouvez contacter l\'équipe de recherche pour toute question.',
    zh: '• 参与完全自愿。\n• 您可随时关闭应用退出。\n• 提交前您可以查看所有收集的数据。\n• 如有任何问题，您可以联系研究团队。',
    ja: '• 参加は完全に任意です。\n• アプリを閉じることでいつでも撤退できます。\n• 提出前にすべての収集データを確認できます。\n• ご質問は研究チームにお問い合わせください。',
    ko: '• 참여는 완전히 자발적입니다.\n• 앱을 닫아 언제든지 철회할 수 있습니다.\n• 제출 전에 수집된 모든 데이터를 검토할 수 있습니다.\n• 질문이 있으면 연구팀에 문의할 수 있습니다.',
    ar: '• المشاركة طوعية تماماً.\n• يمكنك الانسحاب في أي وقت بإغلاق التطبيق.\n• ستتمكن من مراجعة جميع البيانات المجمعة قبل الإرسال.\n• يمكنك التواصل مع فريق البحث بأي أسئلة.',
    ru: '• Участие полностью добровольное.\n• Вы можете выйти в любое время, закрыв приложение.\n• Перед отправкой вы сможете просмотреть все собранные данные.\n• Вы можете обратиться к исследовательской группе с любыми вопросами.',
  );

  String get consentContactTitle => _t(en: 'Contact', de: 'Kontakt', tr: 'İletişim', es: 'Contacto', it: 'Contatto', fr: 'Contact', zh: '联系方式', ja: '連絡先', ko: '연락처', ar: 'التواصل', ru: 'Контакт');
  String get consentContactBody => 'Spinal Cord Injury & Artificial Intelligence Lab\nETH Zurich';
  String get consentCheckbox => _t(en: 'I have read and understood the information above and I consent to participate in this study.', de: 'Ich habe die obigen Informationen gelesen und verstanden und stimme der Teilnahme an dieser Studie zu.', tr: 'Yukarıdaki bilgileri okudum ve anladım ve bu çalışmaya katılmayı kabul ediyorum.', es: 'He leído y comprendido la información anterior y doy mi consentimiento para participar en este estudio.', it: 'Ho letto e compreso le informazioni di cui sopra e acconsento a partecipare a questo studio.', fr: 'J\'ai lu et compris les informations ci-dessus et je consens à participer à cette étude.', zh: '我已阅读并理解以上信息，同意参与本研究。', ja: '上記の情報を読み理解し、この研究への参加に同意します。', ko: '위의 정보를 읽고 이해했으며 이 연구에 참여하는 것에 동의합니다.', ar: 'لقد قرأت المعلومات أعلاه وفهمتها وأوافق على المشاركة في هذه الدراسة.', ru: 'Я прочитал(-а) и понял(-а) информацию выше и даю согласие на участие в этом исследовании.');
  String get consentAgree => _t(en: 'I Agree — Continue', de: 'Ich stimme zu — Weiter', tr: 'Kabul Ediyorum — Devam', es: 'Acepto — Continuar', it: 'Accetto — Continua', fr: 'J\'accepte — Continuer', zh: '同意 — 继续', ja: '同意する — 続ける', ko: '동의합니다 — 계속', ar: 'أوافق — متابعة', ru: 'Согласен — Продолжить');
  String get consentDecline => _t(en: 'Decline', de: 'Ablehnen', tr: 'Reddet', es: 'Rechazar', it: 'Rifiuta', fr: 'Refuser', zh: '拒绝', ja: '拒否', ko: '거부', ar: 'رفض', ru: 'Отклонить');
  String get consentDeclineTitle => _t(en: 'Decline participation', de: 'Teilnahme ablehnen', tr: 'Katılımı reddet', es: 'Rechazar participación', it: 'Rifiuta la partecipazione', fr: 'Refuser la participation', zh: '拒绝参与', ja: '参加を辞退', ko: '참여 거부', ar: 'رفض المشاركة', ru: 'Отклонить участие');
  String get consentDeclineMessage => _t(en: 'You have chosen not to participate. You may close the app at any time.', de: 'Sie haben sich gegen eine Teilnahme entschieden. Sie können die App jederzeit schließen.', tr: 'Katılmamayı seçtiniz. Uygulamayı istediğiniz zaman kapatabilirsiniz.', es: 'Ha elegido no participar. Puede cerrar la aplicación en cualquier momento.', it: 'Hai scelto di non partecipare. Puoi chiudere l\'app in qualsiasi momento.', fr: 'Vous avez choisi de ne pas participer. Vous pouvez fermer l\'application à tout moment.', zh: '您已选择不参与。您可以随时关闭应用。', ja: '参加しないことを選択しました。いつでもアプリを閉じることができます。', ko: '참여하지 않기로 선택했습니다. 언제든지 앱을 닫을 수 있습니다.', ar: 'لقد اخترت عدم المشاركة. يمكنك إغلاق التطبيق في أي وقت.', ru: 'Вы выбрали не участвовать. Вы можете закрыть приложение в любое время.');
  String get goBack => _t(en: 'Go back', de: 'Zurück', tr: 'Geri dön', es: 'Volver', it: 'Torna indietro', fr: 'Retour', zh: '返回', ja: '戻る', ko: '돌아가기', ar: 'عودة', ru: 'Назад');

  // ── Welcome ───────────────────────────────────────────────────────────────
  String get welcomeReady => _t(en: 'Ready to record?', de: 'Bereit zur Aufzeichnung?', tr: 'Kayıt etmeye hazır mısınız?', es: '¿Listo para registrar?', it: 'Pronto a registrare?', fr: 'Prêt à enregistrer?', zh: '准备记录了吗？', ja: '記録する準備はできましたか？', ko: '기록할 준비가 되셨나요?', ar: 'هل أنت مستعد للتسجيل؟', ru: 'Готовы к записи?');
  String get welcomeDescription => _t(en: 'This session collects a wellbeing self-report alongside today\'s health metrics from your device.', de: 'Diese Sitzung erfasst einen Wohlbefindens-Selbstbericht zusammen mit den heutigen Gesundheitsdaten Ihres Geräts.', tr: 'Bu oturum, cihazınızdan bugünün sağlık ölçümleriyle birlikte bir iyilik hali öz raporu toplar.', es: 'Esta sesión recopila un autoinforme de bienestar junto con las métricas de salud de hoy de su dispositivo.', it: 'Questa sessione raccoglie un auto-report sul benessere insieme alle metriche sanitarie odierne del tuo dispositivo.', fr: 'Cette session collecte un auto-rapport de bien-être ainsi que les métriques de santé d\'aujourd\'hui de votre appareil.', zh: '本次会话将收集您设备上的今日健康数据和健康自我报告。', ja: 'このセッションでは、デバイスから本日の健康指標とともに健康度自己報告を収集します。', ko: '이 세션은 기기에서 오늘의 건강 지표와 함께 웰빙 자가 보고를 수집합니다.', ar: 'تجمع هذه الجلسة تقريرًا ذاتيًا عن الرفاهية جنبًا إلى جنب مع مقاييس الصحة اليومية من جهازك.', ru: 'В этой сессии собирается самоотчёт о самочувствии вместе с сегодняшними показателями здоровья вашего устройства.');
  String get welcomeTile1 => _t(en: 'A brief wellbeing questionnaire', de: 'Ein kurzer Wohlbefindensfragebogen', tr: 'Kısa bir iyilik hali anketi', es: 'Un breve cuestionario de bienestar', it: 'Un breve questionario sul benessere', fr: 'Un court questionnaire sur le bien-être', zh: '简短的健康问卷', ja: '簡単な健康度アンケート', ko: '간단한 웰빙 설문지', ar: 'استبيان رفاهية موجز', ru: 'Краткий опросник о самочувствии');
  String get welcomeTile2 => _t(en: 'Steps, heart rate, sleep & active energy', de: 'Schritte, Herzfrequenz, Schlaf & aktive Energie', tr: 'Adımlar, kalp hızı, uyku ve aktif enerji', es: 'Pasos, frecuencia cardíaca, sueño y energía activa', it: 'Passi, frequenza cardiaca, sonno ed energia attiva', fr: 'Pas, fréquence cardiaque, sommeil et énergie active', zh: '步数、心率、睡眠和活动能量', ja: '歩数、心拍数、睡眠、アクティブエネルギー', ko: '걸음 수, 심박수, 수면 및 활동 에너지', ar: 'الخطوات ومعدل ضربات القلب والنوم والطاقة النشطة', ru: 'Шаги, пульс, сон и активная энергия');
  String get welcomeTile3 => _t(en: 'Review everything before submitting', de: 'Alles vor dem Senden überprüfen', tr: 'Göndermeden önce her şeyi inceleyin', es: 'Revise todo antes de enviar', it: 'Rivedi tutto prima di inviare', fr: 'Vérifiez tout avant d\'envoyer', zh: '提交前审查所有内容', ja: '送信前にすべてを確認', ko: '제출 전에 모든 것을 검토', ar: 'راجع كل شيء قبل الإرسال', ru: 'Проверьте всё перед отправкой');
  String get welcomeTile4 => _t(en: 'Offline? Submissions are queued automatically', de: 'Offline? Einsendungen werden automatisch gespeichert', tr: 'Çevrimdışı mı? Gönderimleri otomatik olarak sıraya alınır', es: '¿Sin conexión? Los envíos se guardan automáticamente', it: 'Offline? Le invii vengono messi in coda automaticamente', fr: 'Hors ligne? Les soumissions sont mises en file d\'attente automatiquement', zh: '离线？提交将自动排队', ja: 'オフライン？送信は自動的にキューに追加されます', ko: '오프라인? 제출이 자동으로 대기열에 추가됩니다', ar: 'غير متصل؟ يتم وضع الإرسالات في قائمة انتظار تلقائيًا', ru: 'Офлайн? Отправки автоматически ставятся в очередь');
  String get welcomeStartSurvey => _t(en: 'Start Survey', de: 'Umfrage starten', tr: 'Anketi Başlat', es: 'Iniciar Encuesta', it: 'Avvia Sondaggio', fr: 'Démarrer l\'enquête', zh: '开始调查', ja: 'アンケートを開始', ko: '설문 시작', ar: 'بدء الاستبيان', ru: 'Начать опрос');
  String get welcomeHealthNote => _t(en: 'Tapping "Start Survey" will request access to Health data.', de: 'Durch Tippen auf „Umfrage starten" wird der Zugriff auf Gesundheitsdaten angefordert.', tr: '"Anketi Başlat"a dokunmak Sağlık verilerine erişim talep edecektir.', es: 'Tocar "Iniciar Encuesta" solicitará acceso a los datos de Salud.', it: 'Toccando "Avvia Sondaggio" verrà richiesto l\'accesso ai dati sulla salute.', fr: 'Appuyer sur "Démarrer l\'enquête" demandera l\'accès aux données de santé.', zh: '点击"开始调查"将请求访问健康数据。', ja: '「アンケートを開始」をタップすると、ヘルスデータへのアクセスが要求されます。', ko: '"설문 시작"을 탭하면 건강 데이터 액세스가 요청됩니다.', ar: 'سيطلب النقر على "بدء الاستبيان" الوصول إلى بيانات الصحة.', ru: 'Нажатие «Начать опрос» запросит доступ к данным о здоровье.');
  String get pastSubmissions => _t(en: 'Past submissions', de: 'Frühere Einsendungen', tr: 'Geçmiş gönderimleri', es: 'Envíos anteriores', it: 'Invii precedenti', fr: 'Soumissions précédentes', zh: '过去的提交', ja: '過去の送信', ko: '이전 제출', ar: 'الإرسالات السابقة', ru: 'Прошлые отправки');
  String get settings => _t(en: 'Settings', de: 'Einstellungen', tr: 'Ayarlar', es: 'Configuración', it: 'Impostazioni', fr: 'Paramètres', zh: '设置', ja: '設定', ko: '설정', ar: 'الإعدادات', ru: 'Настройки');

  // ── Form ──────────────────────────────────────────────────────────────────
  String get formTitle => _t(en: 'Questionnaire', de: 'Fragebogen', tr: 'Anket', es: 'Cuestionario', it: 'Questionario', fr: 'Questionnaire', zh: '问卷', ja: 'アンケート', ko: '설문지', ar: 'الاستبيان', ru: 'Анкета');
  String get yourInformation => _t(en: 'Your Information', de: 'Ihre Angaben', tr: 'Bilgileriniz', es: 'Su Información', it: 'Le tue Informazioni', fr: 'Vos Informations', zh: '您的信息', ja: 'あなたの情報', ko: '귀하의 정보', ar: 'معلوماتك', ru: 'Ваша информация');
  String get participantId => _t(en: 'Participant ID', de: 'Teilnehmer-ID', tr: 'Katılımcı Kimliği', es: 'ID de participante', it: 'ID partecipante', fr: 'Identifiant participant', zh: '参与者ID', ja: '参加者ID', ko: '참가자 ID', ar: 'معرف المشارك', ru: 'ID участника');
  String get participantIdHint => _t(en: 'e.g. P-001', de: 'z.B. P-001', tr: 'örn. P-001', es: 'ej. P-001', it: 'es. P-001', fr: 'p.ex. P-001', zh: '例如 P-001', ja: '例: P-001', ko: '예: P-001', ar: 'مثال: P-001', ru: 'напр. P-001');
  String get participantIdError => _t(en: 'Please enter your participant ID', de: 'Bitte geben Sie Ihre Teilnehmer-ID ein', tr: 'Lütfen katılımcı kimliğinizi girin', es: 'Por favor ingrese su ID de participante', it: 'Inserisci il tuo ID partecipante', fr: 'Veuillez entrer votre identifiant participant', zh: '请输入您的参与者ID', ja: '参加者IDを入力してください', ko: '참가자 ID를 입력하세요', ar: 'الرجاء إدخال معرف المشارك', ru: 'Пожалуйста, введите ваш ID участника');
  String get ageRange => _t(en: 'Age Range', de: 'Altersgruppe', tr: 'Yaş Aralığı', es: 'Rango de edad', it: 'Fascia d\'età', fr: 'Tranche d\'âge', zh: '年龄段', ja: '年齢層', ko: '연령대', ar: 'الفئة العمرية', ru: 'Возрастной диапазон');
  String get ageRangeError => _t(en: 'Please select your age range', de: 'Bitte wählen Sie Ihre Altersgruppe', tr: 'Lütfen yaş aralığınızı seçin', es: 'Por favor seleccione su rango de edad', it: 'Seleziona la tua fascia d\'età', fr: 'Veuillez sélectionner votre tranche d\'âge', zh: '请选择您的年龄段', ja: '年齢層を選択してください', ko: '연령대를 선택하세요', ar: 'الرجاء تحديد الفئة العمرية', ru: 'Пожалуйста, выберите возрастной диапазон');
  String get wellbeingRating => _t(en: 'Wellbeing Rating', de: 'Wohlbefindensbewertung', tr: 'İyilik Hali Değerlendirmesi', es: 'Calificación de bienestar', it: 'Valutazione del benessere', fr: 'Évaluation du bien-être', zh: '健康评分', ja: '健康度評価', ko: '웰빙 평가', ar: 'تقييم الرفاهية', ru: 'Оценка самочувствия');
  String get wellbeingQuestion => _t(en: 'How do you feel today overall? (1 = very poor, 5 = excellent)', de: 'Wie fühlen Sie sich heute insgesamt? (1 = sehr schlecht, 5 = ausgezeichnet)', tr: 'Bugün genel olarak nasıl hissediyorsunuz? (1 = çok kötü, 5 = mükemmel)', es: '¿Cómo se siente hoy en general? (1 = muy mal, 5 = excelente)', it: 'Come ti senti oggi in generale? (1 = molto scarso, 5 = eccellente)', fr: 'Comment vous sentez-vous aujourd\'hui? (1 = très mauvais, 5 = excellent)', zh: '您今天总体感觉如何？（1 = 很差，5 = 极好）', ja: '今日の全体的な気分は？（1 = 非常に悪い、5 = 優秀）', ko: '오늘 전반적으로 어떻게 느끼시나요? (1 = 매우 나쁨, 5 = 훌륭함)', ar: 'كيف تشعر اليوم بشكل عام؟ (1 = سيء جداً، 5 = ممتاز)', ru: 'Как вы себя чувствуете сегодня в целом? (1 = очень плохо, 5 = отлично)');
  String get comments => _t(en: 'Comments', de: 'Kommentare', tr: 'Yorumlar', es: 'Comentarios', it: 'Commenti', fr: 'Commentaires', zh: '评论', ja: 'コメント', ko: '의견', ar: 'التعليقات', ru: 'Комментарии');
  String get commentLabel => _t(en: 'Short comment (optional)', de: 'Kurzer Kommentar (optional)', tr: 'Kısa yorum (isteğe bağlı)', es: 'Comentario breve (opcional)', it: 'Breve commento (opzionale)', fr: 'Bref commentaire (optionnel)', zh: '简短评论（可选）', ja: '短いコメント（任意）', ko: '짧은 의견 (선택 사항)', ar: 'تعليق قصير (اختياري)', ru: 'Краткий комментарий (необязательно)');
  String get commentHint => _t(en: 'e.g. Felt energetic in the morning.', de: 'z.B. Fühlte mich morgens energiegeladen.', tr: 'örn. Sabah enerjik hissettim.', es: 'ej. Me sentí energético por la mañana.', it: 'es. Mi sono sentito energico al mattino.', fr: 'p.ex. Je me suis senti énergique le matin.', zh: '例如：早上感觉精力充沛。', ja: '例: 朝は元気でした。', ko: '예: 아침에 활기를 느꼈습니다.', ar: 'مثال: شعرت بالنشاط في الصباح.', ru: 'напр. Утром чувствовал(а) себя бодро.');
  String get reviewAndSubmit => _t(en: 'Review & Submit', de: 'Prüfen & Absenden', tr: 'İncele ve Gönder', es: 'Revisar y Enviar', it: 'Rivedi e Invia', fr: 'Vérifier et Envoyer', zh: '审核并提交', ja: '確認して送信', ko: '검토 및 제출', ar: 'مراجعة وإرسال', ru: 'Проверить и отправить');
  String get ratingVeryPoor => _t(en: 'Very Poor', de: 'Sehr schlecht', tr: 'Çok Kötü', es: 'Muy malo', it: 'Molto scarso', fr: 'Très mauvais', zh: '非常差', ja: '非常に悪い', ko: '매우 나쁨', ar: 'سيء جداً', ru: 'Очень плохо');
  String get ratingPoor => _t(en: 'Poor', de: 'Schlecht', tr: 'Kötü', es: 'Malo', it: 'Scarso', fr: 'Mauvais', zh: '差', ja: '悪い', ko: '나쁨', ar: 'سيء', ru: 'Плохо');
  String get ratingFair => _t(en: 'Fair', de: 'Mittelmäßig', tr: 'Orta', es: 'Regular', it: 'Discreto', fr: 'Passable', zh: '一般', ja: '普通', ko: '보통', ar: 'مقبول', ru: 'Удовлетворительно');
  String get ratingGood => _t(en: 'Good', de: 'Gut', tr: 'İyi', es: 'Bueno', it: 'Buono', fr: 'Bien', zh: '好', ja: '良い', ko: '좋음', ar: 'جيد', ru: 'Хорошо');
  String get ratingExcellent => _t(en: 'Excellent', de: 'Ausgezeichnet', tr: 'Mükemmel', es: 'Excelente', it: 'Eccellente', fr: 'Excellent', zh: '极好', ja: '優秀', ko: '훌륭함', ar: 'ممتاز', ru: 'Отлично');

  // ── Review ────────────────────────────────────────────────────────────────
  String get reviewTitle => _t(en: 'Review', de: 'Überprüfung', tr: 'İnceleme', es: 'Revisión', it: 'Revisione', fr: 'Vérification', zh: '审核', ja: '確認', ko: '검토', ar: 'مراجعة', ru: 'Проверка');
  String get reviewConfirm => _t(en: 'Please confirm your data before submitting.', de: 'Bitte bestätigen Sie Ihre Daten vor dem Absenden.', tr: 'Göndermeden önce lütfen verilerinizi onaylayın.', es: 'Confirme sus datos antes de enviar.', it: 'Conferma i tuoi dati prima di inviare.', fr: 'Confirmez vos données avant d\'envoyer.', zh: '提交前请确认您的数据。', ja: '送信前にデータを確認してください。', ko: '제출 전에 데이터를 확인하세요.', ar: 'يرجى تأكيد بياناتك قبل الإرسال.', ru: 'Пожалуйста, подтвердите ваши данные перед отправкой.');
  String get participant => _t(en: 'Participant', de: 'Teilnehmer', tr: 'Katılımcı', es: 'Participante', it: 'Partecipante', fr: 'Participant', zh: '参与者', ja: '参加者', ko: '참가자', ar: 'المشارك', ru: 'Участник');
  String get wellbeing => _t(en: 'Wellbeing', de: 'Wohlbefinden', tr: 'İyilik Hali', es: 'Bienestar', it: 'Benessere', fr: 'Bien-être', zh: '健康状况', ja: '健康度', ko: '웰빙', ar: 'الرفاهية', ru: 'Самочувствие');
  String get healthMetrics => _t(en: 'Health Metrics', de: 'Gesundheitsmetriken', tr: 'Sağlık Ölçümleri', es: 'Métricas de salud', it: 'Metriche di salute', fr: 'Métriques de santé', zh: '健康指标', ja: '健康指標', ko: '건강 지표', ar: 'مقاييس الصحة', ru: 'Показатели здоровья');
  String get labelId => _t(en: 'ID', de: 'ID', tr: 'Kimlik', es: 'ID', it: 'ID', fr: 'ID', zh: 'ID', ja: 'ID', ko: 'ID', ar: 'المعرف', ru: 'ID');
  String get labelRating => _t(en: 'Rating', de: 'Bewertung', tr: 'Değerlendirme', es: 'Calificación', it: 'Valutazione', fr: 'Évaluation', zh: '评分', ja: '評価', ko: '평가', ar: 'التقييم', ru: 'Оценка');
  String get labelComment => _t(en: 'Comment', de: 'Kommentar', tr: 'Yorum', es: 'Comentario', it: 'Commento', fr: 'Commentaire', zh: '评论', ja: 'コメント', ko: '의견', ar: 'التعليق', ru: 'Комментарий');
  String get labelStepsToday => _t(en: 'Steps today', de: 'Schritte heute', tr: 'Bugünkü adımlar', es: 'Pasos hoy', it: 'Passi oggi', fr: 'Pas aujourd\'hui', zh: '今日步数', ja: '本日の歩数', ko: '오늘 걸음 수', ar: 'الخطوات اليوم', ru: 'Шаги сегодня');
  String get labelHeartRate => _t(en: 'Heart rate', de: 'Herzfrequenz', tr: 'Kalp hızı', es: 'Frecuencia cardíaca', it: 'Frequenza cardiaca', fr: 'Fréquence cardiaque', zh: '心率', ja: '心拍数', ko: '심박수', ar: 'معدل ضربات القلب', ru: 'Пульс');
  String get labelSleep => _t(en: 'Sleep last night', de: 'Schlaf letzte Nacht', tr: 'Dün geceki uyku', es: 'Sueño anoche', it: 'Sonno stanotte', fr: 'Sommeil cette nuit', zh: '昨晚睡眠', ja: '昨夜の睡眠', ko: '어젯밤 수면', ar: 'النوم الليلة الماضية', ru: 'Сон прошлой ночью');
  String get labelActiveEnergy => _t(en: 'Active energy', de: 'Aktive Energie', tr: 'Aktif enerji', es: 'Energía activa', it: 'Energia attiva', fr: 'Énergie active', zh: '活动能量', ja: 'アクティブエネルギー', ko: '활동 에너지', ar: 'الطاقة النشطة', ru: 'Активная энергия');
  String get permissionNotGranted => _t(en: 'Permission not granted', de: 'Berechtigung nicht erteilt', tr: 'İzin verilmedi', es: 'Permiso no otorgado', it: 'Autorizzazione non concessa', fr: 'Autorisation non accordée', zh: '未授予权限', ja: '許可が付与されていません', ko: '권한이 부여되지 않음', ar: 'لم يتم منح الإذن', ru: 'Разрешение не предоставлено');
  String get noData => _t(en: 'No data', de: 'Keine Daten', tr: 'Veri yok', es: 'Sin datos', it: 'Nessun dato', fr: 'Aucune donnée', zh: '无数据', ja: 'データなし', ko: '데이터 없음', ar: 'لا توجد بيانات', ru: 'Нет данных');
  String get submit => _t(en: 'Submit', de: 'Absenden', tr: 'Gönder', es: 'Enviar', it: 'Invia', fr: 'Envoyer', zh: '提交', ja: '送信', ko: '제출', ar: 'إرسال', ru: 'Отправить');
  String get reviewEndpointNote => _t(en: 'Data will be sent to a mock research endpoint (httpbin.org).', de: 'Daten werden an einen simulierten Forschungsendpunkt (httpbin.org) gesendet.', tr: 'Veriler sahte bir araştırma uç noktasına (httpbin.org) gönderilecek.', es: 'Los datos se enviarán a un endpoint de investigación de prueba (httpbin.org).', it: 'I dati saranno inviati a un endpoint di ricerca simulato (httpbin.org).', fr: 'Les données seront envoyées à un endpoint de recherche simulé (httpbin.org).', zh: '数据将发送到模拟研究端点 (httpbin.org)。', ja: 'データはモック研究エンドポイント (httpbin.org) に送信されます。', ko: '데이터는 모의 연구 엔드포인트 (httpbin.org)로 전송됩니다.', ar: 'ستُرسل البيانات إلى نقطة نهاية بحثية تجريبية (httpbin.org).', ru: 'Данные будут отправлены на имитационный исследовательский endpoint (httpbin.org).');

  // ── Result ────────────────────────────────────────────────────────────────
  String get resultTitle => _t(en: 'Submission', de: 'Einsendung', tr: 'Gönderim', es: 'Envío', it: 'Invio', fr: 'Soumission', zh: '提交结果', ja: '送信結果', ko: '제출 결과', ar: 'الإرسال', ru: 'Отправка');
  String get resultSuccessTitle => _t(en: 'Data Submitted', de: 'Daten übermittelt', tr: 'Veri Gönderildi', es: 'Datos enviados', it: 'Dati inviati', fr: 'Données soumises', zh: '数据已提交', ja: 'データ送信完了', ko: '데이터 제출됨', ar: 'تم إرسال البيانات', ru: 'Данные отправлены');
  String get resultSuccessMessage => _t(en: 'Your data was successfully sent to the research endpoint.', de: 'Ihre Daten wurden erfolgreich an den Forschungsendpunkt gesendet.', tr: 'Verileriniz başarıyla araştırma uç noktasına gönderildi.', es: 'Sus datos fueron enviados exitosamente al endpoint de investigación.', it: 'I tuoi dati sono stati inviati con successo all\'endpoint di ricerca.', fr: 'Vos données ont été envoyées avec succès à l\'endpoint de recherche.', zh: '您的数据已成功发送到研究端点。', ja: 'データが研究エンドポイントに正常に送信されました。', ko: '데이터가 연구 엔드포인트로 성공적으로 전송되었습니다.', ar: 'تم إرسال بياناتك بنجاح إلى نقطة نهاية البحث.', ru: 'Ваши данные успешно отправлены на исследовательский endpoint.');
  String get resultQueuedTitle => _t(en: 'Saved for Later', de: 'Für später gespeichert', tr: 'Sonrası İçin Kaydedildi', es: 'Guardado para más tarde', it: 'Salvato per dopo', fr: 'Enregistré pour plus tard', zh: '已保存待发', ja: '後で送信', ko: '나중에 전송 예정', ar: 'محفوظ للإرسال لاحقاً', ru: 'Сохранено для отправки');
  String get resultQueuedMessage => _t(en: 'No internet connection detected. Your submission has been saved locally and will be sent automatically the next time you open the app online.', de: 'Keine Internetverbindung erkannt. Ihre Einsendung wurde lokal gespeichert und wird automatisch gesendet, wenn Sie die App das nächste Mal mit Internet öffnen.', tr: 'İnternet bağlantısı algılanamadı. Gönderiminiz yerel olarak kaydedildi ve bir sonraki çevrimiçi açılışınızda otomatik olarak gönderilecek.', es: 'No se detectó conexión a internet. Su envío se guardó localmente y se enviará automáticamente la próxima vez que abra la app en línea.', it: 'Nessuna connessione internet rilevata. Il tuo invio è stato salvato localmente e verrà inviato automaticamente la prossima volta che apri l\'app online.', fr: 'Aucune connexion internet détectée. Votre soumission a été sauvegardée localement et sera envoyée automatiquement la prochaine fois que vous ouvrirez l\'application en ligne.', zh: '未检测到互联网连接。您的提交已本地保存，下次在线打开应用时将自动发送。', ja: 'インターネット接続が検出されませんでした。送信データはローカルに保存され、次回オンラインでアプリを開いたときに自動的に送信されます。', ko: '인터넷 연결이 감지되지 않았습니다. 제출이 로컬에 저장되었으며 다음에 앱을 온라인으로 열 때 자동으로 전송됩니다.', ar: 'لم يتم اكتشاف اتصال إنترنت. تم حفظ إرسالك محلياً وسيتم إرساله تلقائياً في المرة القادمة التي تفتح فيها التطبيق عبر الإنترنت.', ru: 'Подключение к интернету не обнаружено. Ваша отправка сохранена локально и будет автоматически отправлена при следующем открытии приложения онлайн.');
  String get resultQueuedNote => _t(en: 'Your data is safely stored on this device.', de: 'Ihre Daten sind sicher auf diesem Gerät gespeichert.', tr: 'Verileriniz bu cihazda güvenli şekilde saklanmaktadır.', es: 'Sus datos están almacenados de forma segura en este dispositivo.', it: 'I tuoi dati sono archiviati in modo sicuro su questo dispositivo.', fr: 'Vos données sont stockées en toute sécurité sur cet appareil.', zh: '您的数据安全地存储在此设备上。', ja: 'データはこのデバイスに安全に保存されています。', ko: '데이터는 이 기기에 안전하게 저장되어 있습니다.', ar: 'بياناتك مخزنة بأمان على هذا الجهاز.', ru: 'Ваши данные надёжно хранятся на этом устройстве.');
  String get resultFailedTitle => _t(en: 'Submission Failed', de: 'Übermittlung fehlgeschlagen', tr: 'Gönderim Başarısız', es: 'Envío fallido', it: 'Invio fallito', fr: 'Soumission échouée', zh: '提交失败', ja: '送信失敗', ko: '제출 실패', ar: 'فشل الإرسال', ru: 'Ошибка отправки');
  String get resultFailedMessage => _t(en: 'Could not reach the endpoint. Check your connection and try again.', de: 'Endpoint nicht erreichbar. Überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.', tr: 'Uç noktaya ulaşılamadı. Bağlantınızı kontrol edin ve tekrar deneyin.', es: 'No se pudo alcanzar el endpoint. Compruebe su conexión e inténtelo de nuevo.', it: 'Impossibile raggiungere l\'endpoint. Controlla la connessione e riprova.', fr: 'Impossible d\'atteindre l\'endpoint. Vérifiez votre connexion et réessayez.', zh: '无法连接端点。请检查您的连接并重试。', ja: 'エンドポイントに接続できませんでした。接続を確認して再試行してください。', ko: '엔드포인트에 접근할 수 없습니다. 연결을 확인하고 다시 시도하세요.', ar: 'تعذر الوصول إلى نقطة النهاية. تحقق من اتصالك وحاول مرة أخرى.', ru: 'Не удалось достичь endpoint. Проверьте соединение и попробуйте снова.');
  String get jsonPayload => _t(en: 'JSON Payload', de: 'JSON-Daten', tr: 'JSON Verisi', es: 'Datos JSON', it: 'Dati JSON', fr: 'Données JSON', zh: 'JSON 数据', ja: 'JSONデータ', ko: 'JSON 페이로드', ar: 'بيانات JSON', ru: 'JSON данные');
  String get copyToClipboard => _t(en: 'Copy to clipboard', de: 'In Zwischenablage kopieren', tr: 'Panoya kopyala', es: 'Copiar al portapapeles', it: 'Copia negli appunti', fr: 'Copier dans le presse-papiers', zh: '复制到剪贴板', ja: 'クリップボードにコピー', ko: '클립보드에 복사', ar: 'نسخ إلى الحافظة', ru: 'Скопировать в буфер обмена');
  String get copied => _t(en: 'Copied to clipboard', de: 'In Zwischenablage kopiert', tr: 'Panoya kopyalandı', es: 'Copiado al portapapeles', it: 'Copiato negli appunti', fr: 'Copié dans le presse-papiers', zh: '已复制到剪贴板', ja: 'クリップボードにコピーしました', ko: '클립보드에 복사되었습니다', ar: 'تم النسخ إلى الحافظة', ru: 'Скопировано в буфер обмена');
  // ── Auth ──────────────────────────────────────────────────────────────────
  String get firstName => _t(en: 'First Name', de: 'Vorname', tr: 'Ad', es: 'Nombre', it: 'Nome', fr: 'Prénom', zh: '名字', ja: '名前', ko: '이름', ar: 'الاسم الأول', ru: 'Имя');
  String get lastName => _t(en: 'Last Name', de: 'Nachname', tr: 'Soyad', es: 'Apellido', it: 'Cognome', fr: 'Nom de famille', zh: '姓氏', ja: '苗字', ko: '성', ar: 'اسم العائلة', ru: 'Фамилия');
  String get firstNameError => _t(en: 'Please enter your first name', de: 'Bitte Vorname eingeben', tr: 'Lütfen adınızı girin', es: 'Por favor ingrese su nombre', it: 'Inserisci il tuo nome', fr: 'Entrez votre prénom', zh: '请输入您的名字', ja: '名前を入力してください', ko: '이름을 입력하세요', ar: 'الرجاء إدخال اسمك الأول', ru: 'Пожалуйста, введите ваше имя');
  String get lastNameError => _t(en: 'Please enter your last name', de: 'Bitte Nachname eingeben', tr: 'Lütfen soyadınızı girin', es: 'Por favor ingrese su apellido', it: 'Inserisci il tuo cognome', fr: 'Entrez votre nom de famille', zh: '请输入您的姓氏', ja: '苗字を入力してください', ko: '성을 입력하세요', ar: 'الرجاء إدخال اسم العائلة', ru: 'Пожалуйста, введите вашу фамилию');
  String get email => _t(en: 'Email', de: 'E-Mail', tr: 'E-posta', es: 'Correo electrónico', it: 'Email', fr: 'E-mail', zh: '电子邮件', ja: 'メールアドレス', ko: '이메일', ar: 'البريد الإلكتروني', ru: 'Электронная почта');
  String get emailError => _t(en: 'Please enter a valid email', de: 'Bitte gültige E-Mail eingeben', tr: 'Geçerli bir e-posta girin', es: 'Ingrese un correo válido', it: 'Inserisci un\'email valida', fr: 'Entrez un email valide', zh: '请输入有效的电子邮件', ja: '有効なメールアドレスを入力してください', ko: '유효한 이메일을 입력하세요', ar: 'الرجاء إدخال بريد إلكتروني صحيح', ru: 'Введите корректный email');
  String get password => _t(en: 'Password', de: 'Passwort', tr: 'Şifre', es: 'Contraseña', it: 'Password', fr: 'Mot de passe', zh: '密码', ja: 'パスワード', ko: '비밀번호', ar: 'كلمة المرور', ru: 'Пароль');
  String get passwordError => _t(en: 'Password must be at least 6 characters', de: 'Passwort muss mindestens 6 Zeichen lang sein', tr: 'Şifre en az 6 karakter olmalı', es: 'La contraseña debe tener al menos 6 caracteres', it: 'La password deve avere almeno 6 caratteri', fr: 'Le mot de passe doit contenir au moins 6 caractères', zh: '密码至少需要6个字符', ja: 'パスワードは6文字以上必要です', ko: '비밀번호는 최소 6자 이상이어야 합니다', ar: 'يجب أن تكون كلمة المرور 6 أحرف على الأقل', ru: 'Пароль должен содержать не менее 6 символов');
  String get confirmPassword => _t(en: 'Confirm Password', de: 'Passwort bestätigen', tr: 'Şifreyi Onayla', es: 'Confirmar contraseña', it: 'Conferma password', fr: 'Confirmer le mot de passe', zh: '确认密码', ja: 'パスワードを確認', ko: '비밀번호 확인', ar: 'تأكيد كلمة المرور', ru: 'Подтвердите пароль');
  String get confirmPasswordError => _t(en: 'Passwords do not match', de: 'Passwörter stimmen nicht überein', tr: 'Şifreler eşleşmiyor', es: 'Las contraseñas no coinciden', it: 'Le password non corrispondono', fr: 'Les mots de passe ne correspondent pas', zh: '密码不匹配', ja: 'パスワードが一致しません', ko: '비밀번호가 일치하지 않습니다', ar: 'كلمات المرور غير متطابقة', ru: 'Пароли не совпадают');
  String get signIn => _t(en: 'Sign In', de: 'Anmelden', tr: 'Giriş Yap', es: 'Iniciar sesión', it: 'Accedi', fr: 'Se connecter', zh: '登录', ja: 'サインイン', ko: '로그인', ar: 'تسجيل الدخول', ru: 'Войти');
  String get signUp => _t(en: 'Create Account', de: 'Konto erstellen', tr: 'Hesap Oluştur', es: 'Crear cuenta', it: 'Crea account', fr: 'Créer un compte', zh: '创建账户', ja: 'アカウント作成', ko: '계정 만들기', ar: 'إنشاء حساب', ru: 'Создать аккаунт');
  String get noAccount => _t(en: 'Don\'t have an account? Sign up', de: 'Kein Konto? Registrieren', tr: 'Hesabınız yok mu? Kayıt olun', es: '¿No tiene cuenta? Regístrese', it: 'Non hai un account? Registrati', fr: 'Pas de compte? S\'inscrire', zh: '没有账户？注册', ja: 'アカウントがない？新規登録', ko: '계정이 없으신가요? 가입하기', ar: 'ليس لديك حساب؟ سجل', ru: 'Нет аккаунта? Зарегистрируйтесь');
  String get haveAccount => _t(en: 'Already have an account? Sign in', de: 'Bereits ein Konto? Anmelden', tr: 'Zaten hesabınız var mı? Giriş yapın', es: '¿Ya tiene cuenta? Inicie sesión', it: 'Hai già un account? Accedi', fr: 'Vous avez déjà un compte? Se connecter', zh: '已有账户？登录', ja: 'すでにアカウントをお持ちですか？サインイン', ko: '이미 계정이 있으신가요? 로그인', ar: 'لديك حساب بالفعل؟ تسجيل الدخول', ru: 'Уже есть аккаунт? Войти');
  String get errorUnexpected => _t(en: 'An unexpected error occurred. Please try again.', de: 'Ein unerwarteter Fehler ist aufgetreten. Bitte versuchen Sie es erneut.', tr: 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.', es: 'Ocurrió un error inesperado. Por favor intente de nuevo.', it: 'Si è verificato un errore imprevisto. Riprova.', fr: 'Une erreur inattendue s\'est produite. Veuillez réessayer.', zh: '发生意外错误，请重试。', ja: '予期しないエラーが発生しました。もう一度お試しください。', ko: '예상치 못한 오류가 발생했습니다. 다시 시도하세요.', ar: 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.', ru: 'Произошла непредвиденная ошибка. Пожалуйста, попробуйте снова.');
  String get errorInvalidCredentials => _t(en: 'Invalid participant ID or password.', de: 'Ungültige Teilnehmer-ID oder Passwort.', tr: 'Geçersiz katılımcı kimliği veya şifre.', es: 'ID de participante o contraseña inválidos.', it: 'ID partecipante o password non validi.', fr: 'Identifiant participant ou mot de passe invalide.', zh: '参与者ID或密码无效。', ja: '参加者IDまたはパスワードが無効です。', ko: '참가자 ID 또는 비밀번호가 잘못되었습니다.', ar: 'معرف المشارك أو كلمة المرور غير صالحة.', ru: 'Неверный ID участника или пароль.');
  String get errorUserExists => _t(en: 'This participant ID is already registered.', de: 'Diese Teilnehmer-ID ist bereits registriert.', tr: 'Bu katılımcı kimliği zaten kayıtlı.', es: 'Este ID de participante ya está registrado.', it: 'Questo ID partecipante è già registrato.', fr: 'Cet identifiant participant est déjà enregistré.', zh: '该参与者ID已注册。', ja: 'この参加者IDはすでに登録されています。', ko: '이 참가자 ID는 이미 등록되어 있습니다.', ar: 'معرف المشارك هذا مسجل بالفعل.', ru: 'Этот ID участника уже зарегистрирован.');

  String get signOutConfirm => _t(en: 'Are you sure you want to sign out?', de: 'Möchten Sie sich wirklich abmelden?', tr: 'Çıkış yapmak istediğinizden emin misiniz?', es: '¿Está seguro de que desea cerrar sesión?', it: 'Sei sicuro di voler uscire?', fr: 'Êtes-vous sûr de vouloir vous déconnecter?', zh: '您确定要退出登录吗？', ja: 'サインアウトしてもよろしいですか？', ko: '로그아웃하시겠습니까?', ar: 'هل أنت متأكد من أنك تريد تسجيل الخروج؟', ru: 'Вы уверены, что хотите выйти?');
  String get signOut => _t(en: 'Sign Out', de: 'Abmelden', tr: 'Çıkış Yap', es: 'Cerrar sesión', it: 'Esci', fr: 'Se déconnecter', zh: '退出登录', ja: 'サインアウト', ko: '로그아웃', ar: 'تسجيل الخروج', ru: 'Выйти');

  // ── Gender & Menstrual ────────────────────────────────────────────────────
  String get gender => _t(en: 'Gender', de: 'Geschlecht', tr: 'Cinsiyet', es: 'Género', it: 'Genere', fr: 'Genre', zh: '性别', ja: '性別', ko: '성별', ar: 'الجنس', ru: 'Пол');
  String get genderError => _t(en: 'Please select your gender', de: 'Bitte Geschlecht auswählen', tr: 'Lütfen cinsiyetinizi seçin', es: 'Por favor seleccione su género', it: 'Seleziona il tuo genere', fr: 'Veuillez sélectionner votre genre', zh: '请选择您的性别', ja: '性別を選択してください', ko: '성별을 선택하세요', ar: 'الرجاء تحديد الجنس', ru: 'Пожалуйста, выберите пол');
  String get genderMale => _t(en: 'Male', de: 'Männlich', tr: 'Erkek', es: 'Masculino', it: 'Maschio', fr: 'Homme', zh: '男', ja: '男性', ko: '남성', ar: 'ذكر', ru: 'Мужской');
  String get genderFemale => _t(en: 'Female', de: 'Weiblich', tr: 'Kadın', es: 'Femenino', it: 'Femmina', fr: 'Femme', zh: '女', ja: '女性', ko: '여성', ar: 'أنثى', ru: 'Женский');
  String get genderOther => _t(en: 'Other', de: 'Andere', tr: 'Diğer', es: 'Otro', it: 'Altro', fr: 'Autre', zh: '其他', ja: 'その他', ko: '기타', ar: 'آخر', ru: 'Другой');
  String get genderPreferNotToSay => _t(en: 'Prefer not to say', de: 'Keine Angabe', tr: 'Belirtmek istemiyorum', es: 'Prefiero no decir', it: 'Preferisco non dire', fr: 'Préfère ne pas répondre', zh: '不愿透露', ja: '回答しない', ko: '밝히지 않음', ar: 'أفضل عدم الإفصاح', ru: 'Не указывать');
  String get menstrualHealth => _t(en: 'Menstrual Health', de: 'Menstruationsgesundheit', tr: 'Adet Sağlığı', es: 'Salud Menstrual', it: 'Salute Mestruale', fr: 'Santé Menstruelle', zh: '经期健康', ja: '月経の健康', ko: '월경 건강', ar: 'الصحة الشهرية', ru: 'Менструальное здоровье');
  String get onPeriodQuestion => _t(en: 'Are you currently on your period?', de: 'Haben Sie gerade Ihre Periode?', tr: 'Şu anda adet görüyor musunuz?', es: '¿Está teniendo su período actualmente?', it: 'Sei attualmente nel tuo ciclo mestruale?', fr: 'Avez-vous vos règles actuellement?', zh: '您目前是否正在月经期间？', ja: '現在、生理中ですか？', ko: '현재 생리 중이신가요?', ar: 'هل أنت في دورتك الشهرية الآن؟', ru: 'У вас сейчас менструация?');
  String get yes => _t(en: 'Yes', de: 'Ja', tr: 'Evet', es: 'Sí', it: 'Sì', fr: 'Oui', zh: '是', ja: 'はい', ko: '예', ar: 'نعم', ru: 'Да');
  String get no => _t(en: 'No', de: 'Nein', tr: 'Hayır', es: 'No', it: 'No', fr: 'Non', zh: '否', ja: 'いいえ', ko: '아니오', ar: 'لا', ru: 'Нет');
  String get newPeriodQuestion => _t(en: 'Did a new period start?', de: 'Hat eine neue Periode begonnen?', tr: 'Yeni bir regl başladı mı?', es: '¿Comenzó un nuevo período?', it: 'È iniziato un nuovo ciclo?', fr: 'Une nouvelle période a-t-elle commencé?', zh: '新的月经开始了吗？', ja: '新しい生理が始まりましたか？', ko: '새로운 생리가 시작되었나요?', ar: 'هل بدأت دورة جديدة؟', ru: 'Началась новая менструация?');
  String get lastPeriodQuestion => _t(en: 'When did your last period start?', de: 'Wann begann Ihre letzte Periode?', tr: 'Son reglinin ilk günü ne zamandı?', es: '¿Cuándo comenzó su último período?', it: 'Quando è iniziato il tuo ultimo ciclo?', fr: 'Quand a commencé vos dernières règles?', zh: '您上次月经是什么时候开始的？', ja: '最後の生理はいつ始まりましたか？', ko: '마지막 생리는 언제 시작되었나요?', ar: 'متى بدأت آخر دورة شهرية؟', ru: 'Когда началась последняя менструация?');
  String get lessThan7Days => _t(en: '< 7 days ago', de: 'Vor < 7 Tagen', tr: '< 7 gün önce', es: 'Hace < 7 días', it: '< 7 giorni fa', fr: 'Il y a < 7 jours', zh: '7天内', ja: '7日未満前', ko: '7일 미만 전', ar: 'منذ أقل من 7 أيام', ru: 'Менее 7 дней назад');
  String get days8to14 => _t(en: '8–14 days ago', de: 'Vor 8–14 Tagen', tr: '8–14 gün önce', es: 'Hace 8–14 días', it: '8–14 giorni fa', fr: 'Il y a 8–14 jours', zh: '8–14天前', ja: '8〜14日前', ko: '8–14일 전', ar: 'منذ 8-14 يومًا', ru: '8–14 дней назад');
  String get days15to21 => _t(en: '15–21 days ago', de: 'Vor 15–21 Tagen', tr: '15–21 gün önce', es: 'Hace 15–21 días', it: '15–21 giorni fa', fr: 'Il y a 15–21 jours', zh: '15–21天前', ja: '15〜21日前', ko: '15–21일 전', ar: 'منذ 15-21 يومًا', ru: '15–21 дней назад');
  String get days22plus => _t(en: '22+ days ago', de: 'Vor 22+ Tagen', tr: '22+ gün önce', es: 'Hace 22+ días', it: '22+ giorni fa', fr: 'Il y a 22+ jours', zh: '22天以上前', ja: '22日以上前', ko: '22일 이상 전', ar: 'منذ 22+ يومًا', ru: '22+ дней назад');
  String get phaseMenstrual => _t(en: 'Menstrual Phase', de: 'Menstruationsphase', tr: 'Menstrüel Faz', es: 'Fase menstrual', it: 'Fase mestruale', fr: 'Phase menstruelle', zh: '月经期', ja: '月経期', ko: '월경기', ar: 'الطور الحيضي', ru: 'Менструальная фаза');
  String get phaseFollicular => _t(en: 'Follicular Phase', de: 'Follikelphase', tr: 'Foliküler Faz', es: 'Fase folicular', it: 'Fase follicolare', fr: 'Phase folliculaire', zh: '卵泡期', ja: '卵胞期', ko: '난포기', ar: 'الطور الجريبي', ru: 'Фолликулярная фаза');
  String get phaseOvulatory => _t(en: 'Ovulatory Phase', de: 'Ovulationsphase', tr: 'Ovülatuar Dönem', es: 'Fase ovulatoria', it: 'Fase ovulatoria', fr: 'Phase ovulatoire', zh: '排卵期', ja: '排卵期', ko: '배란기', ar: 'طور الإباضة', ru: 'Овуляторная фаза');
  String get phaseLuteal => _t(en: 'Luteal Phase', de: 'Lutealphase', tr: 'Luteal Faz', es: 'Fase lútea', it: 'Fase luteale', fr: 'Phase lutéale', zh: '黄体期', ja: '黄体期', ko: '황체기', ar: 'الطور الأصفري', ru: 'Лютеиновая фаза');
  String get cycleDay => _t(en: 'Day', de: 'Tag', tr: 'Gün', es: 'Día', it: 'Giorno', fr: 'Jour', zh: '天', ja: '日目', ko: '일', ar: 'يوم', ru: 'День');

  // ── Sleep ─────────────────────────────────────────────────────────────────
  String get sleepQuality => _t(en: 'Sleep Quality', de: 'Schlafqualität', tr: 'Uyku Kalitesi', es: 'Calidad del sueño', it: 'Qualità del sonno', fr: 'Qualité du sommeil', zh: '睡眠质量', ja: '睡眠の質', ko: '수면 질', ar: 'جودة النوم', ru: 'Качество сна');
  String get sleepQuestion => _t(en: 'How well did you sleep last night?', de: 'Wie gut haben Sie letzte Nacht geschlafen?', tr: 'Geçen gece uykunuzu nasıl değerlendirirsiniz?', es: '¿Cómo fue su sueño anoche?', it: 'Come hai dormito la notte scorsa?', fr: 'Comment avez-vous dormi la nuit dernière?', zh: '您昨晚睡得怎么样？', ja: '昨夜はよく眠れましたか？', ko: '어젯밤 수면의 질은 어땠나요?', ar: 'كيف كانت جودة نومك الليلة الماضية؟', ru: 'Как вы спали прошлой ночью?');

  // ── Pain ──────────────────────────────────────────────────────────────────
  String get painSection => _t(en: 'Pain', de: 'Schmerz', tr: 'Ağrı', es: 'Dolor', it: 'Dolore', fr: 'Douleur', zh: '疼痛', ja: '痛み', ko: '통증', ar: 'الألم', ru: 'Боль');
  String get neuropathicPain => _t(en: 'Neuropathic Pain', de: 'Neuropathischer Schmerz', tr: 'Nöropatik Ağrı', es: 'Dolor neuropático', it: 'Dolore neuropatico', fr: 'Douleur neuropathique', zh: '神经性疼痛', ja: '神経性疼痛', ko: '신경병증성 통증', ar: 'الألم العصبي', ru: 'Нейропатическая боль');
  String get neuropathicPainDesc => _t(en: 'burning, tingling, electric sensation', de: 'Brennen, Kribbeln, elektrisches Gefühl', tr: 'yanma, karıncalanma, elektrik çarpması hissi', es: 'ardor, hormigueo, sensación eléctrica', it: 'bruciore, formicolio, sensazione elettrica', fr: 'brûlure, picotement, sensation électrique', zh: '灼烧、刺痛、电击感', ja: '灼熱感・しびれ・電気感', ko: '타는 느낌, 저림, 전기 충격감', ar: 'حرق، وخز، إحساس كهربائي', ru: 'жжение, покалывание, электрический импульс');
  String get musculoskeletalPain => _t(en: 'Musculoskeletal Pain', de: 'Muskuloskelettaler Schmerz', tr: 'Kas-İskelet Ağrısı', es: 'Dolor musculoesquelético', it: 'Dolore muscoloscheletrico', fr: 'Douleur musculo-squelettique', zh: '肌肉骨骼疼痛', ja: '筋骨格系疼痛', ko: '근골격계 통증', ar: 'ألم عضلي هيكلي', ru: 'Мышечно-скелетная боль');
  String get musculoskeletalPainDesc => _t(en: 'aching, stiffness, pressure sensation', de: 'Schmerzen, Steifheit, Druckgefühl', tr: 'sızlama, gerginlik, baskı hissi', es: 'dolor sordo, rigidez, presión', it: 'dolore sordo, rigidità, pressione', fr: 'douleur sourde, raideur, pression', zh: '酸痛、僵硬、压迫感', ja: '鈍痛・こわばり・圧迫感', ko: '쑤심, 경직, 압박감', ar: 'وجع، تصلب، ضغط', ru: 'ноющая боль, скованность, давление');
  String get painNone => _t(en: 'No pain', de: 'Kein Schmerz', tr: 'Ağrı yok', es: 'Sin dolor', it: 'Nessun dolore', fr: 'Aucune douleur', zh: '无痛', ja: '痛みなし', ko: '통증 없음', ar: 'لا ألم', ru: 'Боли нет');
  String get painWorst => _t(en: 'Worst pain', de: 'Schlimmster Schmerz', tr: 'Dayanılmaz', es: 'Peor dolor', it: 'Peggior dolore', fr: 'Pire douleur', zh: '最剧烈', ja: '最大の痛み', ko: '최악의 통증', ar: 'أشد ألم', ru: 'Невыносимая боль');

  String get startOver => _t(en: 'Start Over', de: 'Neu beginnen', tr: 'Yeniden Başla', es: 'Empezar de nuevo', it: 'Ricomincia', fr: 'Recommencer', zh: '重新开始', ja: 'やり直す', ko: '다시 시작', ar: 'البدء من جديد', ru: 'Начать заново');

  // ── History ───────────────────────────────────────────────────────────────
  String get historyTitle => _t(en: 'History', de: 'Verlauf', tr: 'Geçmiş', es: 'Historial', it: 'Cronologia', fr: 'Historique', zh: '历史记录', ja: '履歴', ko: '기록', ar: 'السجل', ru: 'История');
  String get noSubmissionsYet => _t(en: 'No submissions yet', de: 'Noch keine Einsendungen', tr: 'Henüz gönderim yok', es: 'Aún no hay envíos', it: 'Nessun invio ancora', fr: 'Aucune soumission pour l\'instant', zh: '暂无提交记录', ja: 'まだ送信はありません', ko: '아직 제출 없음', ar: 'لا توجد إرسالات بعد', ru: 'Пока нет отправок');
  String get stepActivity => _t(en: 'Step Activity — Last 7 Days', de: 'Schrittaktivität — Letzte 7 Tage', tr: 'Adım Aktivitesi — Son 7 Gün', es: 'Actividad de pasos — Últimos 7 días', it: 'Attività passi — Ultimi 7 giorni', fr: 'Activité pas — 7 derniers jours', zh: '步行活动 — 最近7天', ja: '歩行活動 — 直近7日間', ko: '걸음 활동 — 최근 7일', ar: 'نشاط الخطوات — آخر 7 أيام', ru: 'Активность шагов — последние 7 дней');
  String get pastSubmissionsHeader => _t(en: 'Past Submissions', de: 'Frühere Einsendungen', tr: 'Geçmiş Gönderimleri', es: 'Envíos anteriores', it: 'Invii precedenti', fr: 'Soumissions précédentes', zh: '过去的提交', ja: '過去の送信', ko: '이전 제출', ar: 'الإرسالات السابقة', ru: 'Прошлые отправки');
  String get statusPending => _t(en: 'Pending', de: 'Ausstehend', tr: 'Beklemede', es: 'Pendiente', it: 'In attesa', fr: 'En attente', zh: '待处理', ja: '保留中', ko: '대기 중', ar: 'معلق', ru: 'В ожидании');
  String get statusSubmitted => _t(en: 'Submitted', de: 'Eingereicht', tr: 'Gönderildi', es: 'Enviado', it: 'Inviato', fr: 'Soumis', zh: '已提交', ja: '送信済み', ko: '제출됨', ar: 'تم الإرسال', ru: 'Отправлено');

  // ── Settings ──────────────────────────────────────────────────────────────
  String get settingsTitle => _t(en: 'Settings', de: 'Einstellungen', tr: 'Ayarlar', es: 'Configuración', it: 'Impostazioni', fr: 'Paramètres', zh: '设置', ja: '設定', ko: '설정', ar: 'الإعدادات', ru: 'Настройки');
  String get account => _t(en: 'Account', de: 'Konto', tr: 'Hesap', es: 'Cuenta', it: 'Account', fr: 'Compte', zh: '账户', ja: 'アカウント', ko: '계정', ar: 'الحساب', ru: 'Аккаунт');
  String get saveChanges => _t(en: 'Save Changes', de: 'Änderungen speichern', tr: 'Değişiklikleri Kaydet', es: 'Guardar cambios', it: 'Salva modifiche', fr: 'Enregistrer', zh: '保存更改', ja: '変更を保存', ko: '변경 저장', ar: 'حفظ التغييرات', ru: 'Сохранить');
  String get changePassword => _t(en: 'Change Password', de: 'Passwort ändern', tr: 'Şifre Değiştir', es: 'Cambiar contraseña', it: 'Cambia password', fr: 'Changer le mot de passe', zh: '更改密码', ja: 'パスワード変更', ko: '비밀번호 변경', ar: 'تغيير كلمة المرور', ru: 'Сменить пароль');
  String get newPassword => _t(en: 'New Password', de: 'Neues Passwort', tr: 'Yeni Şifre', es: 'Nueva contraseña', it: 'Nuova password', fr: 'Nouveau mot de passe', zh: '新密码', ja: '新しいパスワード', ko: '새 비밀번호', ar: 'كلمة المرور الجديدة', ru: 'Новый пароль');
  String get profileUpdated => _t(en: 'Profile updated successfully', de: 'Profil erfolgreich aktualisiert', tr: 'Profil başarıyla güncellendi', es: 'Perfil actualizado correctamente', it: 'Profilo aggiornato con successo', fr: 'Profil mis à jour avec succès', zh: '个人信息已成功更新', ja: 'プロフィールを更新しました', ko: '프로필이 성공적으로 업데이트되었습니다', ar: 'تم تحديث الملف الشخصي بنجاح', ru: 'Профиль успешно обновлён');
  String get passwordChanged => _t(en: 'Password changed successfully', de: 'Passwort erfolgreich geändert', tr: 'Şifre başarıyla değiştirildi', es: 'Contraseña cambiada correctamente', it: 'Password modificata con successo', fr: 'Mot de passe modifié avec succès', zh: '密码已成功更改', ja: 'パスワードを変更しました', ko: '비밀번호가 성공적으로 변경되었습니다', ar: 'تم تغيير كلمة المرور بنجاح', ru: 'Пароль успешно изменён');
  String get appearance => _t(en: 'Appearance', de: 'Erscheinungsbild', tr: 'Görünüm', es: 'Apariencia', it: 'Aspetto', fr: 'Apparence', zh: '外观', ja: '外観', ko: '외관', ar: 'المظهر', ru: 'Внешний вид');
  String get themeMode => _t(en: 'Theme', de: 'Design', tr: 'Tema', es: 'Tema', it: 'Tema', fr: 'Thème', zh: '主题', ja: 'テーマ', ko: '테마', ar: 'المظهر', ru: 'Тема');
  String get themeSystem => _t(en: 'System', de: 'System', tr: 'Sistem', es: 'Sistema', it: 'Sistema', fr: 'Système', zh: '跟随系统', ja: 'システム', ko: '시스템', ar: 'النظام', ru: 'Системная');
  String get themeLight => _t(en: 'Light', de: 'Hell', tr: 'Açık', es: 'Claro', it: 'Chiaro', fr: 'Clair', zh: '浅色', ja: 'ライト', ko: '밝음', ar: 'فاتح', ru: 'Светлая');
  String get themeDark => _t(en: 'Dark', de: 'Dunkel', tr: 'Koyu', es: 'Oscuro', it: 'Scuro', fr: 'Sombre', zh: '深色', ja: 'ダーク', ko: '어두움', ar: 'داكن', ru: 'Тёмная');
  String get language => _t(en: 'Language', de: 'Sprache', tr: 'Dil', es: 'Idioma', it: 'Lingua', fr: 'Langue', zh: '语言', ja: '言語', ko: '언어', ar: 'اللغة', ru: 'Язык');
  String get languageSystem => _t(en: 'System default', de: 'Systemstandard', tr: 'Sistem varsayılanı', es: 'Predeterminado del sistema', it: 'Predefinito di sistema', fr: 'Langue du système', zh: '跟随系统', ja: 'システム設定', ko: '시스템 기본값', ar: 'الافتراضي للنظام', ru: 'Системный');

  // ── Core helper ──────────────────────────────────────────────────────────
  String _t({
    required String en,
    required String de,
    required String tr,
    required String es,
    required String it,
    required String fr,
    required String zh,
    required String ja,
    required String ko,
    required String ar,
    required String ru,
  }) {
    return switch (_lang) {
      'de' => de,
      'tr' => tr,
      'es' => es,
      'it' => it,
      'fr' => fr,
      'zh' => zh,
      'ja' => ja,
      'ko' => ko,
      'ar' => ar,
      'ru' => ru,
      _ => en,
    };
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
