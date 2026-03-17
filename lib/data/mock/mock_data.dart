import 'package:flutter/material.dart';
import '../models/models.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';

class MockData {
  // ─── Mock Advice ───
  static final List<AdviceModel> adviceList = [
    const AdviceModel(
      id: 'a1', title: 'Réduisez votre consommation de sel',
      content: 'Limitez votre apport en sel à moins de 5g par jour. Évitez les aliments transformés et les conserves riches en sodium. Utilisez des herbes aromatiques pour assaisonner vos plats.',
      category: 'nutrition', diseaseType: 'hypertension', iconName: 'restaurant', color: Color(0xFFEF4444),
    ),
    const AdviceModel(
      id: 'a2', title: '30 minutes d\'activité physique par jour',
      content: 'La marche rapide, le vélo ou la natation pendant 30 minutes améliorent significativement votre tension artérielle. Commencez progressivement et augmentez l\'intensité graduellement.',
      category: 'activity', diseaseType: 'hypertension', iconName: 'directions_run', color: Color(0xFF10B981),
    ),
    const AdviceModel(
      id: 'a3', title: 'Prenez vos médicaments régulièrement',
      content: 'Ne sautez jamais une dose de votre traitement antihypertenseur. Prenez-les à la même heure chaque jour pour maintenir un niveau stable dans votre sang.',
      category: 'medication', diseaseType: 'hypertension', iconName: 'medication', color: Color(0xFF163344),
    ),
    const AdviceModel(
      id: 'a4', title: 'Surveillez votre tension deux fois par jour',
      content: 'Mesurez votre tension le matin avant de prendre vos médicaments et le soir avant de dormir. Notez vos résultats dans un carnet de suivi.',
      category: 'prevention', diseaseType: 'hypertension', iconName: 'monitor_heart', color: Color(0xFF8B5CF6),
    ),
    const AdviceModel(
      id: 'a5', title: 'Gérez votre stress au quotidien',
      content: 'La méditation, le yoga ou simplement 10 minutes de respiration profonde par jour peuvent réduire votre tension. Le stress chronique est un facteur aggravant de l\'hypertension.',
      category: 'lifestyle', diseaseType: 'hypertension', iconName: 'self_improvement', color: Color(0xFFF59E0B),
    ),
    const AdviceModel(
      id: 'a6', title: 'Évitez l\'alcool et le tabac',
      content: 'L\'alcool et le tabac augmentent directement la tension artérielle. Réduire ou arrêter ces habitudes peut abaisser votre tension de plusieurs points.',
      category: 'lifestyle', diseaseType: 'hypertension', iconName: 'no_drinks', color: Color(0xFFEF4444),
    ),
    const AdviceModel(
      id: 'a7', title: 'Contrôlez votre glycémie à jeun',
      content: 'Mesurez votre glycémie chaque matin à jeun. Une valeur normale est entre 0.70 et 1.00 g/L. Notez vos résultats et partagez-les avec votre médecin.',
      category: 'prevention', diseaseType: 'diabetes', iconName: 'water_drop', color: Color(0xFF163344),
    ),
    const AdviceModel(
      id: 'a8', title: 'Choisissez des glucides complexes',
      content: 'Préférez les céréales complètes, les légumineuses et les légumes verts aux sucres raffinés. L\'index glycémique bas de ces aliments stabilise votre glycémie.',
      category: 'nutrition', diseaseType: 'diabetes', iconName: 'grain', color: Color(0xFF10B981),
    ),
    const AdviceModel(
      id: 'a9', title: 'L\'exercice réduit la résistance à l\'insuline',
      content: 'Une activité physique régulière améliore la sensibilité à l\'insuline. 150 minutes d\'activité modérée par semaine sont recommandées pour les diabétiques.',
      category: 'activity', diseaseType: 'diabetes', iconName: 'fitness_center', color: Color(0xFFF59E0B),
    ),
    const AdviceModel(
      id: 'a10', title: 'Fractionnez vos repas',
      content: 'Prenez 3 repas équilibrés avec 2 collations légères plutôt que 2 grands repas. Cela évite les pics glycémiques importants et maintient une énergie stable.',
      category: 'nutrition', diseaseType: 'diabetes', iconName: 'restaurant_menu', color: Color(0xFF8B5CF6),
    ),
    const AdviceModel(
      id: 'a11', title: 'Soignez vos pieds chaque jour',
      content: 'Inspectez vos pieds quotidiennement, hydratez-les et évitez de marcher pieds nus. Les complications podologiques du diabète peuvent être graves mais sont évitables.',
      category: 'prevention', diseaseType: 'diabetes', iconName: 'accessibility', color: Color(0xFFEF4444),
    ),
    const AdviceModel(
      id: 'a12', title: 'Dormez 7 à 8 heures par nuit',
      content: 'Un sommeil insuffisant perturbe la régulation de la glycémie et augmente la tension artérielle. Établissez une routine de sommeil régulière pour votre santé.',
      category: 'lifestyle', diseaseType: 'all', iconName: 'bedtime', color: Color(0xFF163344),
    ),
    const AdviceModel(
      id: 'a13', title: 'Buvez suffisamment d\'eau',
      content: 'Consommez au moins 1.5 à 2 litres d\'eau par jour. L\'eau aide les reins à éliminer le sodium, ce qui contribue à réguler la tension artérielle et la glycémie.',
      category: 'nutrition', diseaseType: 'all', iconName: 'local_drink', color: Color(0xFF3B82F6),
    ),
    const AdviceModel(
      id: 'a14', title: 'Consultez votre médecin régulièrement',
      content: 'Ne ratez jamais vos consultations de suivi, même si vous vous sentez bien. Votre médecin peut ajuster votre traitement avant que des complications n\'apparaissent.',
      category: 'prevention', diseaseType: 'all', iconName: 'local_hospital', color: Color(0xFF10B981),
    ),
    const AdviceModel(
      id: 'a15', title: 'Maintenez un poids santé',
      content: 'Chaque kilo perdu réduit la tension artérielle d\'environ 1 mmHg et améliore la sensibilité à l\'insuline. Une alimentation équilibrée et l\'exercice sont la clé.',
      category: 'nutrition', diseaseType: 'all', iconName: 'monitor_weight', color: Color(0xFFF59E0B),
    ),
  ];

  // ─── Mock Events ───
  static final List<EventModel> events = [
    EventModel(
      id: 'e1', title: 'Journée sportive communautaire',
      description: 'Une matinée de sport et de bien-être pour tous les habitants du quartier. Activités : marche, aerobics, yoga, et jeux collectifs. Venez en famille !',
      date: DateTime.now().add(const Duration(days: 3)),
      time: const TimeOfDay(hour: 7, minute: 0),
      location: 'Stade municipal de Logopé', organizer: 'Mairie de Agoè-Nyivé', category: 'sport',
    ),
    EventModel(
      id: 'e2', title: 'Dépistage gratuit hypertension & diabète',
      description: 'Campagne de dépistage gratuite organisée par le CHU de Treichville. Tests de glycémie, mesure de tension artérielle et consultations gratuites.',
      date: DateTime.now().add(const Duration(days: 7)),
      time: const TimeOfDay(hour: 8, minute: 30),
      location: 'Université de Lomé', organizer: 'CHU Tokoin', category: 'health',
      maxParticipants: 200,
    ),
    EventModel(
      id: 'e3', title: 'Campagne de nettoyage - Marchés propres',
      description: 'Opération de salubrité dans les marchés populaires. Rejoignez les équipes de bénévoles pour un environnement plus sain dans nos marchés.',
      date: DateTime.now().add(const Duration(days: 5)),
      time: const TimeOfDay(hour: 6, minute: 0),
      location: 'Marché de Adjamé 220 logements', organizer: 'ONG Environnement+', category: 'cleaning',
    ),
    EventModel(
      id: 'e4', title: 'Conférence : Alimentation et maladies chroniques',
      description: 'Une conférence pour comprendre le lien entre alimentation et maladies cardiovasculaires. Avec Pr. Koffi Amoussou, cardiologue.',
      date: DateTime.now().add(const Duration(days: 10)),
      time: const TimeOfDay(hour: 15, minute: 0),
      location: 'Salle des fêtes de CCL', organizer: 'Association Cœur Sain', category: 'awareness',
    ),
    EventModel(
      id: 'e5', title: 'Marathon de la santé - 5km pour tous',
      description: 'Course caritative dont les fonds financeront les soins de patients démunis. Ouverte à tous niveaux. T-shirt et kit offerts.',
      date: DateTime.now().add(const Duration(days: 14)),
      time: const TimeOfDay(hour: 7, minute: 30),
      location: 'Boulevard de la République, Plateau', organizer: 'Fondation Santé CI', category: 'sport',
      maxParticipants: 500,
    ),
    EventModel(
      id: 'e6', title: 'Atelier cuisine santé pour diabétiques',
      description: 'Apprenez à cuisiner des repas délicieux adaptés aux diabétiques. Démonstration par une diététicienne et dégustation incluses.',
      date: DateTime.now().add(const Duration(days: 6)),
      time: const TimeOfDay(hour: 10, minute: 0),
      location: 'Centre communautaire de Kodjoviakopé', organizer: 'Association Diabète CI', category: 'health',
    ),
  ];

  // ─── Mock Assessment Questions ───
  static final List<SelfAssessmentQuestion> assessmentQuestions = [
    SelfAssessmentQuestion(
      id: 'q1',
      question: 'Quelle est votre activité physique hebdomadaire ?',
      category: 'activity',
      options: [
        const SelfAssessmentOption(id: 'q1a', label: 'Plus de 150 min / semaine', riskScore: 0),
        const SelfAssessmentOption(id: 'q1b', label: 'Entre 60 et 150 min / semaine', riskScore: 1),
        const SelfAssessmentOption(id: 'q1c', label: 'Moins de 60 min / semaine', riskScore: 2),
        const SelfAssessmentOption(id: 'q1d', label: 'Sédentaire (aucune activité)', riskScore: 3),
      ],
    ),
    SelfAssessmentQuestion(
      id: 'q2',
      question: 'Comment décrivez-vous votre consommation de sucre ?',
      category: 'nutrition',
      options: [
        const SelfAssessmentOption(id: 'q2a', label: 'Très faible (pas de sucreries ni sodas)', riskScore: 0),
        const SelfAssessmentOption(id: 'q2b', label: 'Modérée (quelques sucreries par semaine)', riskScore: 1),
        const SelfAssessmentOption(id: 'q2c', label: 'Élevée (sucreries ou sodas quotidiens)', riskScore: 2),
        const SelfAssessmentOption(id: 'q2d', label: 'Très élevée (plusieurs fois par jour)', riskScore: 3),
      ],
    ),
    SelfAssessmentQuestion(
      id: 'q3',
      question: 'Quelle est votre consommation de sel ?',
      category: 'nutrition',
      options: [
        const SelfAssessmentOption(id: 'q3a', label: 'Peu salé, évite les aliments transformés', riskScore: 0),
        const SelfAssessmentOption(id: 'q3b', label: 'Modérée, parfois des aliments transformés', riskScore: 1),
        const SelfAssessmentOption(id: 'q3c', label: 'Souvent des aliments salés ou transformés', riskScore: 2),
        const SelfAssessmentOption(id: 'q3d', label: 'Alimentation très salée quotidiennement', riskScore: 3),
      ],
    ),
    SelfAssessmentQuestion(
      id: 'q4',
      question: 'Fumez-vous du tabac ?',
      category: 'smoking',
      options: [
        const SelfAssessmentOption(id: 'q4a', label: 'Non, jamais', riskScore: 0),
        const SelfAssessmentOption(id: 'q4b', label: 'Ancien fumeur (sevré depuis > 1 an)', riskScore: 1),
        const SelfAssessmentOption(id: 'q4c', label: 'Occasionnellement', riskScore: 2),
        const SelfAssessmentOption(id: 'q4d', label: 'Oui, régulièrement', riskScore: 3),
      ],
    ),
    SelfAssessmentQuestion(
      id: 'q5',
      question: 'Comment décrivez-vous votre niveau de stress ?',
      category: 'stress',
      options: [
        const SelfAssessmentOption(id: 'q5a', label: 'Faible, je gère bien mon stress', riskScore: 0),
        const SelfAssessmentOption(id: 'q5b', label: 'Modéré, quelques tensions occasionnelles', riskScore: 1),
        const SelfAssessmentOption(id: 'q5c', label: 'Élevé, souvent stressé(e)', riskScore: 2),
        const SelfAssessmentOption(id: 'q5d', label: 'Très élevé, stress chronique permanent', riskScore: 3),
      ],
    ),
    SelfAssessmentQuestion(
      id: 'q6',
      question: 'Avez-vous des antécédents familiaux de maladies chroniques ?',
      category: 'family_history',
      options: [
        const SelfAssessmentOption(id: 'q6a', label: 'Non, aucun antécédent connu', riskScore: 0),
        const SelfAssessmentOption(id: 'q6b', label: 'Parents éloignés (oncles, grands-parents)', riskScore: 1),
        const SelfAssessmentOption(id: 'q6c', label: 'Un parent direct (père ou mère)', riskScore: 2),
        const SelfAssessmentOption(id: 'q6d', label: 'Deux parents ou plus touchés', riskScore: 3),
      ],
    ),
    SelfAssessmentQuestion(
      id: 'q7',
      question: 'Comment décrivez-vous votre alimentation globale ?',
      category: 'nutrition',
      options: [
        const SelfAssessmentOption(id: 'q7a', label: 'Équilibrée, fruits et légumes quotidiens', riskScore: 0),
        const SelfAssessmentOption(id: 'q7b', label: 'Acceptable, quelques légumes par semaine', riskScore: 1),
        const SelfAssessmentOption(id: 'q7c', label: 'Peu équilibrée, peu de fruits et légumes', riskScore: 2),
        const SelfAssessmentOption(id: 'q7d', label: 'Déséquilibrée, fast-food et plats gras', riskScore: 3),
      ],
    ),
    SelfAssessmentQuestion(
      id: 'q8',
      question: 'Consommez-vous de l\'alcool ?',
      category: 'lifestyle',
      options: [
        const SelfAssessmentOption(id: 'q8a', label: 'Non, jamais ou très rarement', riskScore: 0),
        const SelfAssessmentOption(id: 'q8b', label: 'Occasionnellement (< 2 verres/semaine)', riskScore: 1),
        const SelfAssessmentOption(id: 'q8c', label: 'Régulièrement (2-4 verres/semaine)', riskScore: 2),
        const SelfAssessmentOption(id: 'q8d', label: 'Fréquemment (> 4 verres/semaine)', riskScore: 3),
      ],
    ),
  ];

  // ─── Mock Screening Reminders ───
  static List<ScreeningReminder> defaultScreeningReminders = [
    ScreeningReminder(
      id: 'sr1', title: 'Bilan sanguin annuel',
      description: 'Glycémie à jeun, bilan lipidique, créatinine', frequency: 'annual',
      dueDate: DateTime.now().add(const Duration(days: 45)),
    ),
    ScreeningReminder(
      id: 'sr2', title: 'Électrocardiogramme',
      description: 'ECG de contrôle cardiaque', frequency: 'annual',
      dueDate: DateTime.now().add(const Duration(days: 120)),
    ),
    ScreeningReminder(
      id: 'sr3', title: 'Fond d\'œil',
      description: 'Dépistage de la rétinopathie', frequency: 'annual',
      dueDate: DateTime.now().add(const Duration(days: 60)),
    ),
    ScreeningReminder(
      id: 'sr4', title: 'Consultation cardiologique',
      description: 'Suivi cardiologique de routine', frequency: 'annual',
      dueDate: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  
  // ─── Mock Simple Reminders ───
  static List<SimpleReminder> defaultSimpleReminders = [
    SimpleReminder(
      id: 'sim1', label: 'Peser-moi ce matin',
      date: DateTime.now(), time: const TimeOfDay(hour: 7, minute: 0),
    ),
    SimpleReminder(
      id: 'sim2', label: 'Rendez-vous Dr. Kouassi',
      date: DateTime.now().add(const Duration(days: 3)),
      time: const TimeOfDay(hour: 10, minute: 30),
    ),
  ];

  // ─── Mock Hypertension Records ───
  static List<HypertensionRecord> hypertensionRecords(String userId) => [
    HypertensionRecord(
      id: 'hr1', userId: userId, systolic: 135, diastolic: 85,
      temperature: 37.2, heartRate: 72,
      measuredAt: DateTime.now().subtract(const Duration(hours: 2)),
      comment: 'Après repos', context: 'repos',
    ),
    HypertensionRecord(
      id: 'hr2', userId: userId, systolic: 128, diastolic: 82,
      temperature: 37.1, heartRate: 68,
      measuredAt: DateTime.now().subtract(const Duration(days: 1, hours: 14)),
      context: 'matin',
    ),
    HypertensionRecord(
      id: 'hr3', userId: userId, systolic: 140, diastolic: 90,
      temperature: 37.5, heartRate: 80,
      measuredAt: DateTime.now().subtract(const Duration(days: 2)),
      comment: 'Stress professionnel', context: 'stress',
    ),
    HypertensionRecord(
      id: 'hr4', userId: userId, systolic: 132, diastolic: 84,
      temperature: 37.0, heartRate: 74,
      measuredAt: DateTime.now().subtract(const Duration(days: 3)),
      context: 'repos',
    ),
    HypertensionRecord(
      id: 'hr5', userId: userId, systolic: 127, diastolic: 80,
      temperature: 37.2, heartRate: 70,
      measuredAt: DateTime.now().subtract(const Duration(days: 4)),
      context: 'matin',
    ),
    HypertensionRecord(
      id: 'hr6', userId: userId, systolic: 138, diastolic: 88,
      temperature: 37.1, heartRate: 76,
      measuredAt: DateTime.now().subtract(const Duration(days: 5)),
      context: 'soir',
    ),
    HypertensionRecord(
      id: 'hr7', userId: userId, systolic: 130, diastolic: 83,
      temperature: 37.3, heartRate: 71,
      measuredAt: DateTime.now().subtract(const Duration(days: 6)),
      context: 'matin',
    ),
  ];

  // ─── Mock Diabetes Records ───
  static List<DiabetesRecord> diabetesRecords(String userId) => [
    DiabetesRecord(
      id: 'dr1', userId: userId, glucoseLevel: 0.95,
      temperature: 37.1, heartRate: 72,
      measuredAt: DateTime.now().subtract(const Duration(hours: 2)),
      comment: 'À jeun', context: 'a_jeun',
    ),
    DiabetesRecord(
      id: 'dr2', userId: userId, glucoseLevel: 1.45,
      temperature: 37.2, heartRate: 75,
      measuredAt: DateTime.now().subtract(const Duration(days: 1)),
      comment: 'Après repas', context: 'post_prandial',
    ),
    DiabetesRecord(
      id: 'dr3', userId: userId, glucoseLevel: 0.92,
      temperature: 37.0, heartRate: 70,
      measuredAt: DateTime.now().subtract(const Duration(days: 2)),
      context: 'a_jeun',
    ),
    DiabetesRecord(
      id: 'dr4', userId: userId, glucoseLevel: 1.20,
      temperature: 37.3, heartRate: 78,
      measuredAt: DateTime.now().subtract(const Duration(days: 3)),
      context: 'post_prandial',
    ),
    DiabetesRecord(
      id: 'dr5', userId: userId, glucoseLevel: 0.88,
      temperature: 37.1, heartRate: 68,
      measuredAt: DateTime.now().subtract(const Duration(days: 4)),
      context: 'a_jeun',
    ),
    DiabetesRecord(
      id: 'dr6', userId: userId, glucoseLevel: 1.55,
      temperature: 37.4, heartRate: 80,
      measuredAt: DateTime.now().subtract(const Duration(days: 5)),
      comment: 'Repas copieux', context: 'post_prandial',
    ),
  ];

  // ─── Mock Hospitals ───
  static const List<Hospital> hospitals = [
    Hospital(id: 'h1', name: 'Dokita Lafia', address: 'Agoè Zongo, Lomé', district: 'Agoè', phone: '+228 99 99 92 00'),
    Hospital(id: 'h2', name: 'CHU de Tokoin', address: 'Bd de l\'Université de Lomé, Lomé', district: 'Lomé', phone: '+228 22 22 06 66'),
    Hospital(id: 'h3', name: 'Polyclinique Internationale Sainte Anne-Marie', address: 'Lomé, Lomé', district: 'Lomé', phone: '+228 97 97 11 11'),
    Hospital(id: 'h4', name: 'Hôpital Général de Logopé', address: 'Logopé, Lomé', district: 'Lomé', phone: '+228 93 47 11 11'),
    Hospital(id: 'h5', name: 'Clinique du Plateau', address: 'Plateau, Lomé', district: 'Plateau', phone: '+228 91 10 10 40'),
  ];

  // ─── Mock user ───
  static final UserModel mockUser = UserModel(
    id: 'u1',
    firstName: 'Bima',
    lastName: 'Afi',
    email: 'bima.afi@email.com',
    phone: '+228 91 56 78 00',
    dateOfBirth: DateTime(1985, 6, 15),
    residence: 'LOmé',
    district: 'Agoe',
    healthStatus: 'patient',
    diseaseType: 'hypertension',
    weight: 75.0,
    height: 170.0,
  );

  static final UserModel mockNonPatientUser = UserModel(
    id: 'u2',
    firstName: 'Konan',
    lastName: 'Marie',
    email: 'konan.marie@email.com',
    phone: '+228 91 30 74 81',
    dateOfBirth: DateTime(2000, 3, 20),
    residence: 'Lomé',
    district: 'Segbé',
    healthStatus: 'non_patient',
  );


  static List<NotificationModel> generateMockNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: const Uuid().v4(),
        title: 'Prise de médicament',
        body: 'Il est temps de prendre votre Amlodipine 5mg',
        type: NotificationType.medicationReminder,
        createdAt: now.subtract(const Duration(minutes: 20)),
      ),
      NotificationModel(
        id: const Uuid().v4(),
        title: 'Stock faible',
        body: 'Il vous reste seulement 5 unités de Metformine. Pensez à renouveler votre ordonnance.',
        type: NotificationType.medicationRenewal,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: const Uuid().v4(),
        title: 'Mesure manquée',
        body: 'Vous n\'avez pas effectué votre mesure de glycémie de ce matin',
        type: NotificationType.missedMeasurement,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      NotificationModel(
        id: const Uuid().v4(),
        title: 'Rendez-vous médical',
        body: 'Le Dr. Kouassi vous demande de venir à l\'hôpital ce jeudi à 10h. En cas d\'empêchement, contactez le +228 93 93 06 66.',
        type: NotificationType.doctorAppointment,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationModel(
        id: const Uuid().v4(),
        title: 'Rendez-vous imminent',
        body: 'Votre consultation de routine est dans 2 jours (Vendredi 10h)',
        type: NotificationType.doctorAppointment,
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
        isRead: true,
      ),
      NotificationModel(
        id: const Uuid().v4(),
        title: 'Dépistage à venir',
        body: 'Bilan sanguin annuel prévu dans 7 jours',
        type: NotificationType.screeningReminder,
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
      NotificationModel(
        id: const Uuid().v4(),
        title: 'Nouvel événement',
        body: 'Journée sportive communautaire dans 3 jours',
        type: NotificationType.eventReminder,
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }

  static List<Prescription> mockPrescriptions = [
    Prescription(
      id: 'rx1',
      reference: 'ORD-2024-001',
      imageLocalPath: null,
      prescriptionDate: DateTime.now().subtract(const Duration(days: 15)),
      doctorName: 'Dr. Kouassi',
      hospital: 'CHU de Cocody',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),

    Prescription(
      id: 'rx2',
      reference: 'ORD-2024-002',
      prescriptionDate: DateTime.now().subtract(const Duration(days: 7)),
      doctorName: 'Dr. Amoussou',
      hospital: 'CHU de Treichville',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];
    // Mettre à jour defaultMedicationReminders
  static List<MedicationReminder> defaultMedicationReminders = [
    MedicationReminder(
      id: 'mr1',
      medicationName: 'Amlodipine',
      dosage: '5mg',
      intakeTimes: [const TimeOfDay(hour: 7, minute: 30)],
      stock: 14,
      renewalAlertThreshold: 7,
      diseaseType: 'hypertension',
      prescriptionId: 'rx1', // ← Lier à l'ordonnance
    ),

    MedicationReminder(
      id: 'mr2',
      medicationName: 'Metformine',
      dosage: '500mg',
      intakeTimes: [
      const TimeOfDay(hour: 7, minute: 0),
      const TimeOfDay(hour: 19, minute: 0),
      ],
      stock: 5,
      renewalAlertThreshold: 7,
      diseaseType: 'diabetes',
      prescriptionId: 'rx2', // ← Lier à l'ordonnance
      ),
  ];
}
