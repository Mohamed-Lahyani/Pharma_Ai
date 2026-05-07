const bwipjs = require('bwip-js');
const fs = require('fs');

// Création dossier
if (!fs.existsSync('barcodes')) {
    fs.mkdirSync('barcodes');
}

// Médicaments
const medications = [
    {
        name: 'Doliprane_1000mg',
        barcode: '340093670001'
    },
    {
        name: 'Augmentin_1g',
        barcode: '340093725001'
    },
    {
        name: 'Ventoline',
        barcode: '340093710000'
    }
];

async function generate() {

    for (const med of medications) {

        try {

            const png = await bwipjs.toBuffer({
                bcid: 'ean13',
                text: med.barcode,
                scale: 3,
                height: 10,
                includetext: true,
            });

            fs.writeFileSync(
                `barcodes/${med.name}.png`,
                png
            );

            console.log(`✅ Généré : ${med.name}`);

        } catch (err) {
            console.error(err);
        }
    }

    console.log('🎉 Tous les barcodes générés');
}

generate();