// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.5.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.5.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.5.0/access/Ownable.sol";

contract loteria is ERC20, Ownable {

    // ==================================================
    // Gestion de los tokens
    // ==================================================

    // Direccion del contrato NFT del proyecto
    address public nft;

    // Constructor
    constructor() ERC20("Loteria", "JA") {
        _mint(address(this), 1000);
        nft = address(new mainERC721());
    }

    // Ganador del premio de la loteria
    address public ganador;

    // Registro del usuario
    mapping(address => address) public usuario_contract;

    // Precio de los tokens
    function precioTokens(uint256 _numTokens) internal pure returns (uint256) {
        return _numTokens * (1 ether);
    }

    // Visualizacion del balance de tokens ERC20 de un usuario
    function balanceTokens(address _account) public view returns (uint256) {
        return balanceOf(_account);
    }

    // Visualizacion del balance de tokens ERC20 de un Smart Contract
    function balanceTokensSC() public view returns (uint256) {
        return balanceOf(address(this));
    }

    // Visualizacion del balance de ethers del Smart Contract
    // 1ther -> 10^18
     function balanceethersSC() public view returns (uint256) {
        return address(this).balance / 10**18;
    }

    // Generacion de nuevos  Tokens ERC-20
    function mint(uint256 _cantidad) public onlyOwner {
        _mint(address(this), _cantidad);
    }

    // Registro de usuarios
    function registrar() internal {
        address addr_personal_contract = address(new boletosNFTs(msg.sender, address(this), nft));
        usuario_contract[msg.sender] = addr_personal_contract;
    }

    // Informacion de un usuario
    function usersInfo(address _account) public view returns (address) {
        return usuario_contract[_account];
    }

    // Compra de tokens ERC20
    function compraTokens(uint256 _numTokens) public payable {
        // Registro del usuario
        if(usuario_contract[msg.sender] == address(0)) {
            registrar();
        }
        // Establecimiento del coste de los tokens a comprar
        uint256 coste = precioTokens(_numTokens);
        // Evalucaion del dinero que el cliente paga por los tokens
        require(msg.value >= coste, "Compra menos tokens o paga con mas ethers");
        // Obtencion del numero de tokens ERC-20 disponibles
        uint256 balance = balanceTokensSC();
        require(_numTokens <= balance, "Compra un numero menor de tokens");
        // Devolucion del dinero sobrante
        uint256 returnValue = msg.value - coste;
        // El smart Contract devuelve la cantidad restante
        payable(msg.sender).transfer(returnValue);
        // Envio de los tokens al cliente/usuario
        _transfer(address(this), msg.sender, _numTokens);

    }

    // Devolucion de tokens al Smart Contract
    function devolverTokens(uint _numTokens) public payable {
        // El numero de tokens debe ser mayor a 0
        require(_numTokens >0, "Necesitas devolver un numero de tokens mayor a 0");
        // El usuario debe acreditar tener los tokens que quiere devolver
        require(_numTokens <= balanceTokens(msg.sender), "No tienes los tokens que deseas devolver");
        // El usuario transfiere los tokens al Smart Contract 
        _transfer(msg.sender, address(this), _numTokens);
        // El Smart Contract envia los ethers al usuario
        payable(msg.sender).transfer(precioTokens(_numTokens));
    }

    // ==================================================
    // Gestion de los tokens
    // ==================================================

    // Precio del boleto de la loteria (En tokens ERC20)
    uint public precioBoleto = 5;
    // Relacion: persona quecompra los boletos -> el numero de los boletos
    mapping(address => uint [] ) idPersona_boletos;
    // Relacion: boleto -> ganador
    mapping(uint => address) ADNBoleto;
    // Numero aleatorio
    uint randNonce = 0;
    // Boletos de la loteria generadors
    uint [] boletosComprados;

    // Compra de boletos de loteria
    function compraBoleto(uint _numBoletos) public {
        // Precio total de los boletos a comprar
        uint precioTotal = _numBoletos * precioBoleto;
        // Verificacion de los tokens del usuario
        require(precioTotal <= balanceTokens(msg.sender), "No tienes tokens suficientes");
        // Trasferencia de tokens del usuario al Smart Contract
        _transfer(msg.sender, address(this), precioTotal);

        for (uint i = 0; i < _numBoletos; i++) {
            uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 10000;
            randNonce++;
            // Almacenamiento de los datos del boleto enlazados al usuario
            idPersona_boletos[msg.sender].push(random);
            // Almacenamiento de los boletos
            boletosComprados.push(random);
            // Asignacion del ADN del boleto para la generacion de un ganador
            ADNBoleto[random] = msg.sender;
            // Creacion de un nuevo NFT para el numero de boleto
            boletosNFTs(usuario_contract[msg.sender]).mintBoleto(msg.sender, random);
        }
    }

    // Visualizacion de los boletos del usuario
    function tusBoletos(address _propietario) public view returns(uint [] memory) {
        return idPersona_boletos[_propietario];
    }

    // Generador del ganador de la loteria
    function generadorGanador() public onlyOwner {
        // Declaracion de la longuitud del array
        uint longitud = boletosComprados.length;
        // Verificacion de la compra de al menos 1 boleto
        require(boletosComprados.length > 0, "No hay boletos comprados");
        // Elecion aleatoria entre un numero entre : [0-Longuitud]
        uint random = uint(keccak256(abi.encodePacked(block.timestamp))) % longitud;
        // Seleccion del numero aleatorio
        uint eleccion = boletosComprados[random];
        // Direccion del ganador de la loteria
        ganador = ADNBoleto[eleccion];
        // Envio del 95% del premio de loteria del ganador
        payable(ganador).transfer(address(this).balance *95 / 100);
        // Envio del 5% del premio de la loteria al owner
        payable(owner()).transfer(address(this).balance *5 / 100);
    }
}

// Smart Contrtact de NFTs
contract mainERC721 is ERC721 {

    address public direcionLoteria;
    constructor() ERC721("Loteria", "STE") {
        direcionLoteria = msg.sender;
    }

        // Creacion de NFTs
        function safeMint(address _propietario, uint256 _boleto) public {
            require(msg.sender == loteria(direcionLoteria).usersInfo(_propietario), "No tienes permisos para ejecutar esta funcion");
            _safeMint(_propietario, _boleto);
        }

    
}

contract boletosNFTs {

    // Datos relevantes del propietario
    struct Owner {
        address direccionPropietario;
        address contratoPadre;
        address contratoNFT;
        address contratoUuario;
    }
    // Estructura de datos de tipo Owner
    Owner public propietario;

    // Constructor del Smart Contract (hijo)
    constructor(address _propietario, address _contratoPadre, address _contratoNFT) {
        propietario = Owner(_propietario, _contratoPadre, _contratoNFT, address(this));
    }

    // Conversion de los numeros de los boletos de loteria
    function mintBoleto(address _propietario, uint _boleto) public {
        require(msg.sender == propietario.contratoPadre, "No tienes permisos para ejecutar esta funcion");
        mainERC721(propietario.contratoNFT).safeMint(_propietario, _boleto);
    }

}