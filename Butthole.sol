pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// PENNIES ERC-20 Token Contract
contract Pennies is ERC20 {
    uint256 public constant MAX_SUPPLY = 1e9 * 1e18; // 1 billion PENNIES

    constructor() ERC20("Pennies", "PENNY") {
        _mint(msg.sender, MAX_SUPPLY);
    }
}

// Butthole ERC-721 Contract
contract Butthole is ERC721, ReentrancyGuard {
    Pennies public penniesToken;
    IUniswapV2Router02 public uniswapRouter;

    // Constants
    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 public constant PENNIES_PER_BUTTHOLE = 10000;
    uint256 public constant PENNIES_DAILY_SHOVE = 100;
    uint256 public lastShoveTime;
    uint256 public totalSupply;

    // Mappings
    mapping(uint256 => uint256) public buttholePennies;

    constructor(address _penniesTokenAddress, address _uniswapRouterAddress) ERC721("Butthole", "BHOLE") {
        penniesToken = Pennies(_penniesTokenAddress);
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
        lastShoveTime = block.timestamp;
    }

    function mintButthole() public payable nonReentrant {
        require(msg.value == MINT_PRICE, "Incorrect mint price");
        require(totalSupply < 10000, "Max supply reached");
        
        uint256 newButtholeId = totalSupply + 1;
        _mint(msg.sender, newButtholeId);
        buttholePennies[newButtholeId] = PENNIES_PER_BUTTHOLE;
        totalSupply++;

        penniesToken.approve(address(uniswapRouter), PENNIES_PER_BUTTHOLE);

        uniswapRouter.addLiquidityETH{value: msg.value}(
            address(penniesToken),
            PENNIES_PER_BUTTHOLE,
            0, 
            0, 
            address(this),
            block.timestamp
        );
    }

    function dailyShove() public nonReentrant {
        require(block.timestamp >= lastShoveTime + 1 days, "Can only shove once per day");
        uint256 totalPenniesToDistribute = totalSupply * PENNIES_DAILY_SHOVE;
        require(penniesToken.totalSupply() + totalPenniesToDistribute <= Pennies.MAX_SUPPLY, "Exceeds max PENNIES supply");

        for (uint256 i = 1; i <= totalSupply; i++) {
            if (_exists(i)) {
                buttholePennies[i] += PENNIES_DAILY_SHOVE;
            }
        }
        lastShoveTime = block.timestamp;
    }

    function unshove(uint256 buttholeId) public nonReentrant {
        require(ownerOf(buttholeId) == msg.sender, "You must own the butthole to unshove");
        uint256 penniesAmount = buttholePennies[buttholeId] / 2;
        buttholePennies[buttholeId] = 0;
        penniesToken.transfer(msg.sender, penniesAmount);
    }

    function burnButthole(uint256 buttholeId) public nonReentrant {
        require(ownerOf(buttholeId) == msg.sender, "You must own the butthole to burn");
        uint256 penniesAmount = buttholePennies[buttholeId];
        buttholePennies[buttholeId] = 0;
        _burn(buttholeId);
        penniesToken.transfer(msg.sender, penniesAmount);
    }

    function getPenniesInButthole(uint256 buttholeId) public view returns (uint256) {
        require(_exists(buttholeId), "Butthole does not exist");
        return buttholePennies[buttholeId];
    }
}
