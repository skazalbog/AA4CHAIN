const { ethers } = require("ethers");

async function main() {
  const account = "0xTuDireccionAqui"; // Reemplaza con tu dirección pública

  const provider = new ethers.providers.JsonRpcProvider(
    "https://sepolia.infura.io/v3/9dbb78c4bc954e4fbc9d182d3c096001"
  );

  const balance = await provider.getBalance(account);

  console.log(`Saldo de ${account}: ${ethers.utils.formatEther(balance)} ETH`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

