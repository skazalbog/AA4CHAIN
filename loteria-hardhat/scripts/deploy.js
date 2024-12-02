async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    // Asegúrate de que el nombre del contrato aquí coincida con el nombre del contrato en el archivo Solidity
    const Loteria = await ethers.getContractFactory("Loteria");  // Cambio aquí
    const loteria = await Loteria.deploy();  // Despliegue del contrato
  
    console.log("Loteria contract deployed to:", loteria.address);
  
    // Espera hasta que el contrato esté desplegado
    await loteria.deployed();
    console.log("Loteria contract deployed!");
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  