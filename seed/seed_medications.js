// ============================================================
//  SEED FIREBASE - 50 Médicaments avec vrais codes EAN-13
//  Usage :
//    1. npm install firebase-admin
//    2. Mets ton serviceAccountKey.json dans le même dossier
//    3. node seed_medications.js
// ============================================================

const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ============================================================
//  50 MÉDICAMENTS AVEC VRAIS CODES EAN-13
// ============================================================
const medications = [

  // ── ANTIDOULEUR ──────────────────────────────────────────
  {
    name: "Doliprane 1000mg",
    barcode: "3400936700017",
    price: 65.0,
    stock: 150,
    description: "Paracétamol adulte. Max 4g/jour. Espacer les prises d'au moins 4h. Ne pas dépasser 8 comprimés par jour.",
    category: "Antidouleur",
    expiryDate: new Date("2026-12-31"),
  },
  {
    name: "Doliprane 500mg",
    barcode: "3400936609587",
    price: 45.0,
    stock: 200,
    description: "Paracétamol 500mg. 1 à 2 comprimés toutes les 4 à 6 heures. Max 8 comprimés/jour.",
    category: "Antidouleur",
    expiryDate: new Date("2027-03-31"),
  },
  {
    name: "Efferalgan 1000mg effervescent",
    barcode: "3400937420038",
    price: 80.0,
    stock: 90,
    description: "Paracétamol effervescent. Dissoudre dans un verre d'eau. Max 4g/jour.",
    category: "Antidouleur",
    expiryDate: new Date("2026-09-30"),
  },
  {
    name: "Dafalgan Odis 500mg",
    barcode: "5054563016140",
    price: 70.0,
    stock: 75,
    description: "Paracétamol orodispersible. Se dissout sur la langue sans eau. Idéal en déplacement.",
    category: "Antidouleur",
    expiryDate: new Date("2026-06-30"),
  },
  {
    name: "Tramadol 50mg",
    barcode: "3400935800005",
    price: 110.0,
    stock: 20,
    description: "Antalgique opioïde faible. Douleurs modérées à sévères. Sur ordonnance obligatoire.",
    category: "Antidouleur",
    expiryDate: new Date("2026-08-31"),
  },

  // ── ANTI-INFLAMMATOIRE ───────────────────────────────────
  {
    name: "Ibuprofène Mylan 400mg",
    barcode: "3400935101579",
    price: 75.0,
    stock: 110,
    description: "AINS. Douleurs et fièvre. Prendre au cours d'un repas. Ne pas dépasser 3 comprimés/jour.",
    category: "Anti-inflammatoire",
    expiryDate: new Date("2027-01-31"),
  },
  {
    name: "Nurofen 400mg",
    barcode: "5000158104938",
    price: 95.0,
    stock: 85,
    description: "Ibuprofène 400mg. Maux de tête, règles douloureuses, fièvre. Prendre avec de la nourriture.",
    category: "Anti-inflammatoire",
    expiryDate: new Date("2026-11-30"),
  },
  {
    name: "Voltarène Emulgel 1%",
    barcode: "7613421012481",
    price: 145.0,
    stock: 60,
    description: "Diclofénac gel topique. Application locale 3 à 4 fois/jour. Douleurs musculaires et articulaires.",
    category: "Anti-inflammatoire",
    expiryDate: new Date("2027-06-30"),
  },
  {
    name: "Kétoprofène LP 100mg",
    barcode: "3400936000012",
    price: 85.0,
    stock: 45,
    description: "AINS à libération prolongée. 1 gélule/jour au cours d'un repas. Sur ordonnance.",
    category: "Anti-inflammatoire",
    expiryDate: new Date("2026-10-31"),
  },
  {
    name: "Célécoxib 200mg",
    barcode: "3400938200009",
    price: 220.0,
    stock: 30,
    description: "Anti-COX2 sélectif. Arthrose et polyarthrite rhumatoïde. Sur ordonnance.",
    category: "Anti-inflammatoire",
    expiryDate: new Date("2027-02-28"),
  },

  // ── ANTIBIOTIQUE ─────────────────────────────────────────
  {
    name: "Amoxicilline Sandoz 500mg",
    barcode: "3400934000038",
    price: 120.0,
    stock: 40,
    description: "Pénicilline large spectre. 1 gélule 3 fois/jour pendant 7 jours. Sur ordonnance.",
    category: "Antibiotique",
    expiryDate: new Date("2026-05-31"),
  },
  {
    name: "Augmentin 1g",
    barcode: "3400937250016",
    price: 185.0,
    stock: 35,
    description: "Amoxicilline + Acide clavulanique. Infections résistantes. 1 comprimé 2x/jour. Ordonnance.",
    category: "Antibiotique",
    expiryDate: new Date("2026-07-31"),
  },
  {
    name: "Azithromycine 250mg",
    barcode: "3400934500007",
    price: 150.0,
    stock: 25,
    description: "Macrolide. 2 gélules le 1er jour puis 1/jour pendant 4 jours. Sur ordonnance.",
    category: "Antibiotique",
    expiryDate: new Date("2026-04-30"),
  },
  {
    name: "Ciprofloxacine 500mg",
    barcode: "3400935300002",
    price: 130.0,
    stock: 28,
    description: "Fluoroquinolone. Infections urinaires et respiratoires. Sur ordonnance. Ne pas prendre avec du lait.",
    category: "Antibiotique",
    expiryDate: new Date("2026-09-30"),
  },
  {
    name: "Métronidazole 500mg",
    barcode: "3400934700001",
    price: 95.0,
    stock: 50,
    description: "Antiparasitaire et antibiotique. Infections anaérobies. Éviter l'alcool pendant le traitement.",
    category: "Antibiotique",
    expiryDate: new Date("2027-04-30"),
  },

  // ── ANTIHISTAMINIQUE ─────────────────────────────────────
  {
    name: "Zyrtec 10mg",
    barcode: "3400935614044",
    price: 95.0,
    stock: 70,
    description: "Cétirizine. Rhinite allergique, urticaire. 1 comprimé/jour le soir. Peu sédatif.",
    category: "Antihistaminique",
    expiryDate: new Date("2027-08-31"),
  },
  {
    name: "Aerius 5mg",
    barcode: "5060024070048",
    price: 110.0,
    stock: 55,
    description: "Desloratadine. Allergie sans somnolence. 1 comprimé/jour. Peut être pris à tout moment.",
    category: "Antihistaminique",
    expiryDate: new Date("2027-05-31"),
  },
  {
    name: "Loratadine 10mg",
    barcode: "3400935900004",
    price: 65.0,
    stock: 80,
    description: "Antihistaminique non sédatif. Rhume des foins et allergies cutanées. 1 comprimé/jour.",
    category: "Antihistaminique",
    expiryDate: new Date("2027-02-28"),
  },
  {
    name: "Polaramine 2mg",
    barcode: "3400933500008",
    price: 55.0,
    stock: 60,
    description: "Dexchlorphéniramine. Allergies, démangeaisons. Peut provoquer de la somnolence.",
    category: "Antihistaminique",
    expiryDate: new Date("2026-12-31"),
  },

  // ── ANTIHYPERTENSEUR ─────────────────────────────────────
  {
    name: "Amlodipine Teva 5mg",
    barcode: "3400936100035",
    price: 110.0,
    stock: 45,
    description: "Inhibiteur calcique. Hypertension et angor. 1 comprimé/jour. Sur ordonnance.",
    category: "Antihypertenseur",
    expiryDate: new Date("2026-11-30"),
  },
  {
    name: "Ramipril 5mg",
    barcode: "3400936200008",
    price: 98.0,
    stock: 40,
    description: "IEC. Hypertension et insuffisance cardiaque. 1 comprimé/jour. Sur ordonnance.",
    category: "Antihypertenseur",
    expiryDate: new Date("2027-01-31"),
  },
  {
    name: "Losartan 50mg",
    barcode: "3400936300001",
    price: 125.0,
    stock: 35,
    description: "Sartan. Hypertension artérielle et protection rénale. 1 comprimé/jour. Sur ordonnance.",
    category: "Antihypertenseur",
    expiryDate: new Date("2026-08-31"),
  },
  {
    name: "Bisoprolol 5mg",
    barcode: "3400936400004",
    price: 88.0,
    stock: 50,
    description: "Bêtabloquant. Hypertension et insuffisance cardiaque. Ne jamais arrêter brutalement.",
    category: "Antihypertenseur",
    expiryDate: new Date("2027-03-31"),
  },

  // ── ANTIDIABÉTIQUE ───────────────────────────────────────
  {
    name: "Glucophage 500mg",
    barcode: "3400938095283",
    price: 90.0,
    stock: 55,
    description: "Metformine. Diabète type 2. Prendre pendant ou après les repas. Sur ordonnance.",
    category: "Antidiabétique",
    expiryDate: new Date("2026-10-31"),
  },
  {
    name: "Glucophage 850mg",
    barcode: "3400938095290",
    price: 105.0,
    stock: 48,
    description: "Metformine 850mg. Diabète type 2. 1 comprimé 2 à 3 fois/jour avec les repas.",
    category: "Antidiabétique",
    expiryDate: new Date("2026-10-31"),
  },
  {
    name: "Diamicron MR 30mg",
    barcode: "3400936500007",
    price: 135.0,
    stock: 30,
    description: "Gliclazide à libération modifiée. Diabète type 2. Prendre au petit déjeuner.",
    category: "Antidiabétique",
    expiryDate: new Date("2027-05-31"),
  },

  // ── ANTIDÉPRESSEUR ───────────────────────────────────────
  {
    name: "Prozac 20mg",
    barcode: "3400935200003",
    price: 165.0,
    stock: 22,
    description: "Fluoxétine. Dépression et TOC. 1 gélule/jour le matin. Effet à partir de 2-4 semaines.",
    category: "Antidépresseur",
    expiryDate: new Date("2027-07-31"),
  },
  {
    name: "Seroplex 10mg",
    barcode: "3400935200010",
    price: 145.0,
    stock: 25,
    description: "Escitalopram. Dépression et anxiété généralisée. 1 comprimé/jour. Sur ordonnance.",
    category: "Antidépresseur",
    expiryDate: new Date("2026-12-31"),
  },
  {
    name: "Laroxyl 25mg",
    barcode: "3400933800007",
    price: 75.0,
    stock: 30,
    description: "Amitriptyline. Dépression et douleurs chroniques. Prendre le soir. Sur ordonnance.",
    category: "Antidépresseur",
    expiryDate: new Date("2026-11-30"),
  },

  // ── ANXIOLYTIQUE ─────────────────────────────────────────
  {
    name: "Xanax 0.25mg",
    barcode: "3400934500059",
    price: 95.0,
    stock: 3,
    description: "Alprazolam. Anxiété et attaques de panique. Usage court terme. Ordonnance sécurisée.",
    category: "Anxiolytique",
    expiryDate: new Date("2026-04-30"),
  },
  {
    name: "Lexomil 6mg",
    barcode: "3400934600001",
    price: 65.0,
    stock: 4,
    description: "Bromazépam. Anxiété. Traitement de courte durée. Peut créer une dépendance.",
    category: "Anxiolytique",
    expiryDate: new Date("2026-03-31"),
  },
  {
    name: "Atarax 25mg",
    barcode: "3400933700000",
    price: 55.0,
    stock: 40,
    description: "Hydroxyzine. Anxiété et prurit. Non benzodiazépine. Peut provoquer somnolence.",
    category: "Anxiolytique",
    expiryDate: new Date("2027-01-31"),
  },

  // ── CARDIOVASCULAIRE ─────────────────────────────────────
  {
    name: "Tahor 20mg",
    barcode: "3400935700008",
    price: 185.0,
    stock: 50,
    description: "Atorvastatine. Réduction du cholestérol. Prendre le soir. Sur ordonnance.",
    category: "Cardiovasculaire",
    expiryDate: new Date("2027-06-30"),
  },
  {
    name: "Plavix 75mg",
    barcode: "3400935700015",
    price: 240.0,
    stock: 28,
    description: "Clopidogrel. Prévention des thromboses. 1 comprimé/jour. Sur ordonnance.",
    category: "Cardiovasculaire",
    expiryDate: new Date("2026-09-30"),
  },
  {
    name: "Kardégic 75mg",
    barcode: "3400935750004",
    price: 45.0,
    stock: 90,
    description: "Aspirine cardio. Prévention des accidents cardiovasculaires. 1 sachet/jour avec de l'eau.",
    category: "Cardiovasculaire",
    expiryDate: new Date("2027-08-31"),
  },

  // ── GASTRO-ENTÉROLOGIE ───────────────────────────────────
  {
    name: "Inexium 20mg",
    barcode: "3400935050006",
    price: 130.0,
    stock: 65,
    description: "Ésoméprazole. Reflux gastro-œsophagien. 1 comprimé/jour avant le repas.",
    category: "Gastro-entérologie",
    expiryDate: new Date("2027-04-30"),
  },
  {
    name: "Mopral 20mg",
    barcode: "3400935050013",
    price: 115.0,
    stock: 70,
    description: "Oméprazole. Ulcères gastriques. 1 gélule/jour avant le repas du matin.",
    category: "Gastro-entérologie",
    expiryDate: new Date("2027-02-28"),
  },
  {
    name: "Smecta 3g",
    barcode: "3400935150003",
    price: 55.0,
    stock: 120,
    description: "Dioctite de smectite. Diarrhée et douleurs digestives. 3 sachets/jour. Sans ordonnance.",
    category: "Gastro-entérologie",
    expiryDate: new Date("2028-01-31"),
  },
  {
    name: "Imodium 2mg",
    barcode: "5000158040946",
    price: 70.0,
    stock: 85,
    description: "Lopéramide. Diarrhée aiguë. 2 gélules puis 1 après chaque selle liquide. Max 8/jour.",
    category: "Gastro-entérologie",
    expiryDate: new Date("2027-10-31"),
  },
  {
    name: "Gaviscon liquide",
    barcode: "5010605600015",
    price: 125.0,
    stock: 55,
    description: "Alginates. Brûlures d'estomac et remontées acides. 10 à 20ml après les repas.",
    category: "Gastro-entérologie",
    expiryDate: new Date("2026-08-31"),
  },

  // ── PNEUMOLOGIE ──────────────────────────────────────────
  {
    name: "Ventoline 100µg/dose",
    barcode: "3400937100007",
    price: 180.0,
    stock: 30,
    description: "Salbutamol. Bronchodilatateur. 1 à 2 bouffées en cas de crise d'asthme.",
    category: "Pneumologie",
    expiryDate: new Date("2026-10-31"),
  },
  {
    name: "Seretide 25/250µg",
    barcode: "3400937200001",
    price: 420.0,
    stock: 15,
    description: "Salmétérol + Fluticasone. Asthme persistant. 2 bouffées 2x/jour. Sur ordonnance.",
    category: "Pneumologie",
    expiryDate: new Date("2026-06-30"),
  },
  {
    name: "Mucomyst 200mg",
    barcode: "3400937300004",
    price: 75.0,
    stock: 60,
    description: "Acétylcystéine. Fluidifiant bronchique. 1 sachet 3x/jour dans un verre d'eau.",
    category: "Pneumologie",
    expiryDate: new Date("2027-03-31"),
  },

  // ── DERMATOLOGIE ─────────────────────────────────────────
  {
    name: "Bétaméthasone crème 0.05%",
    barcode: "3400933000040",
    price: 85.0,
    stock: 45,
    description: "Corticoïde fort. Eczéma et psoriasis. Application fine 1x/jour. Ne pas utiliser longtemps.",
    category: "Dermatologie",
    expiryDate: new Date("2026-07-31"),
  },
  {
    name: "Biafine émulsion",
    barcode: "3400935400005",
    price: 95.0,
    stock: 50,
    description: "Tréthanolamine. Brûlures légères et irritations. Appliquer en couche épaisse.",
    category: "Dermatologie",
    expiryDate: new Date("2027-09-30"),
  },

  // ── OPHTALMOLOGIE ────────────────────────────────────────
  {
    name: "Visine gouttes oculaires",
    barcode: "3574661622330",
    price: 65.0,
    stock: 40,
    description: "Tétrazoline. Rougeurs oculaires. 1 à 2 gouttes 2 à 3 fois/jour. Max 4 jours.",
    category: "Ophtalmologie",
    expiryDate: new Date("2026-12-31"),
  },
  {
    name: "Artelac collyre",
    barcode: "4046445001002",
    price: 110.0,
    stock: 35,
    description: "Hypromellose. Yeux secs et irrités. 1 à 2 gouttes selon besoin. Sans conservateur.",
    category: "Ophtalmologie",
    expiryDate: new Date("2027-01-31"),
  },

  // ── PÉDIATRIE ────────────────────────────────────────────
  {
    name: "Doliprane 2.4% sirop",
    barcode: "3400936750018",
    price: 55.0,
    stock: 75,
    description: "Paracétamol sirop enfants. 15mg/kg toutes les 6h. Agiter avant utilisation.",
    category: "Pédiatrie",
    expiryDate: new Date("2026-09-30"),
  },
  {
    name: "Advil 20mg/ml suspension",
    barcode: "3400938300002",
    price: 75.0,
    stock: 60,
    description: "Ibuprofène pédiatrique. 10mg/kg 3x/jour. Pour enfants de 3 mois à 12 ans.",
    category: "Pédiatrie",
    expiryDate: new Date("2026-11-30"),
  },
  {
    name: "Toplexil sirop",
    barcode: "3400937500003",
    price: 65.0,
    stock: 45,
    description: "Oxomémazine. Toux et rhume enfants. Selon l'âge. Peut provoquer somnolence.",
    category: "Pédiatrie",
    expiryDate: new Date("2027-02-28"),
  },

  // ── VITAMINES & COMPLÉMENTS ──────────────────────────────
  {
    name: "Uvédose Vitamine D3 100 000 UI",
    barcode: "3760028980042",
    price: 85.0,
    stock: 180,
    description: "Cholécalciférol. Carence en vitamine D. 1 ampoule/mois. A diluer dans de l'eau.",
    category: "Vitamines & Compléments",
    expiryDate: new Date("2028-06-30"),
  },
  {
    name: "Magné B6",
    barcode: "3400930050009",
    price: 90.0,
    stock: 140,
    description: "Magnésium + Vitamine B6. Fatigue, crampes, stress. 3 à 6 comprimés/jour.",
    category: "Vitamines & Compléments",
    expiryDate: new Date("2027-12-31"),
  },
];

// ============================================================
//  IMPORT DANS FIREBASE
// ============================================================
async function seedMedications() {
  console.log("🚀 Début de l'import...\n");

  const batch = db.batch();
  let count = 0;

  for (const med of medications) {
    const docRef = db.collection("medications").doc();
    batch.set(docRef, {
      ...med,
      expiryDate: admin.firestore.Timestamp.fromDate(med.expiryDate),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`  ✅ [${med.barcode}] ${med.name}`);
    count++;
  }

  await batch.commit();
  console.log(`\n🎉 Import terminé ! ${count} médicaments ajoutés dans Firebase.`);
  process.exit(0);
}

seedMedications().catch((err) => {
  console.error("❌ Erreur :", err);
  process.exit(1);
});