const bwipjs = require('bwip-js');
const QRCode = require('qrcode');
const fs = require('fs');

// ============================================================
// MÉDICAMENTS
// ============================================================
const medications = [
  {
    name: 'Doliprane 1000mg',
    barcode: '3400936700013',
  },
  {
    name: 'Augmentin 1g',
    barcode: '3400937250013',
  },
  {
    name: 'Ventoline 100µg/dose',
    barcode: '3400937100008',
  },
  {
    name: 'Smecta 3g',
    barcode: '3400935150003',
  },
  {
    name: 'Kardégic 75mg',
    barcode: '3400935750004',
  },
];

// ============================================================
// DOSSIERS
// ============================================================
if (!fs.existsSync('./barcodes')) {
  fs.mkdirSync('./barcodes');
}

if (!fs.existsSync('./qrcodes')) {
  fs.mkdirSync('./qrcodes');
}

// ============================================================
// GÉNÉRATION
// ============================================================
async function generateCodes() {
  for (const med of medications) {
    const safeName = med.name.replace(/[^a-zA-Z0-9]/g, '_');

    // ========================================================
    // CODE BARRES EAN13
    // ========================================================
    try {
      const png = await bwipjs.toBuffer({
        bcid: 'ean13',
        text: med.barcode,
        scale: 3,
        height: 10,
        includetext: true,
        textxalign: 'center',
      });

      fs.writeFileSync(`./barcodes/${safeName}.png`, png);

      console.log(`✅ Barcode généré : ${med.name}`);
    } catch (err) {
      console.error(`❌ Erreur barcode ${med.name}`, err);
    }

    // ========================================================
    // QR CODE
    // ========================================================
    try {
      const qrData = JSON.stringify(med);

      await QRCode.toFile(
        `./qrcodes/${safeName}.png`,
        qrData,
        {
          width: 300,
        }
      );

      console.log(`✅ QR Code généré : ${med.name}`);
    } catch (err) {
      console.error(`❌ Erreur QR ${med.name}`, err);
    }
  }

  console.log('\n🎉 Tous les codes ont été générés !');
}

generateCodes();