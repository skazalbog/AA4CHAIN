const { ethers } = require("ethers");

const PRIVATE_KEY = "50b18b1553b15bcb211f3155c4bc7c2839c6bb262fde2c961d8c6b56a4bb913c"; // Reemplaza con tu clave privada

const wallet = new ethers.Wallet(PRIVATE_KEY);
console.log("Address:", wallet.address);

