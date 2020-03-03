const fs = require('fs');

// destination.txt will be created or overwritten by default.
fs.copyFile('./build/contracts/TokenDistribution.json', './src/assets/smartcontracts/TokenDistribution.json', (err) => {
  if (err) throw err;
  console.log('TokenDistributor.txt was copied to assets');
});
