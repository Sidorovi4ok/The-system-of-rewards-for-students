// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStudentRewards.sol";

contract ShopManagement is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MERCHANDISER_ROLE = keccak256("MERCHANDISER_ROLE");
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");

    struct Product {
        uint32 amount;
        uint32 price;
        bytes32 name;
        string description;
        Category category;
        bool exist;
    }

    struct Purchase {
        address buyer;
        uint256 productId;
        uint32 price;
        uint32 timeBuy;
        uint32 timeReturn;
        PurchaseStatus status;
    }

    enum Category {
        BAKERY,
        STATIONERY,
        COUPON
    }

    enum PurchaseStatus {
        REQUESTED,
        CONFIRMED,
        COMPLETED,
        RETURN_REQUESTED,
        RETURNED
    }

    IERC20 public rewardsToken;
    mapping(uint256 => Product) public products;
    mapping(uint256 => Purchase) public purchases;
    mapping(address => uint256[]) public studentPurchases;
    uint256 private _productCounter;
    uint256 private _purchaseCounter;

    event ProductCreated(uint256 indexed productId, bytes32 name, uint32 price);
    event ProductUpdated(uint256 indexed productId, uint32 amount, uint32 price);
    event ProductPurchased(uint256 indexed productId, address indexed buyer, uint32 price);
    event PurchaseReturned(uint256 indexed purchaseId, address indexed buyer);

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "ShopManagement: caller is not an admin");
        _;
    }

    modifier onlyMerchandiser() {
        require(hasRole(MERCHANDISER_ROLE, msg.sender), "ShopManagement: caller is not a merchandiser");
        _;
    }

    constructor(address _rewardsToken) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        rewardsToken = IERC20(_rewardsToken);
    }

    function createProduct(
        bytes32 name,
        string memory description,
        Category category,
        uint32 amount,
        uint32 price
    ) external onlyMerchandiser whenNotPaused {
        require(amount > 0, "ShopManagement: amount must be greater than 0");
        require(price > 0, "ShopManagement: price must be greater than 0");

        uint256 productId = _productCounter++;
        products[productId] = Product({
            amount: amount,
            price: price,
            name: name,
            description: description,
            category: category,
            exist: true
        });

        emit ProductCreated(productId, name, price);
    }

    function updateProduct(
        uint256 productId,
        uint32 amount,
        uint32 price
    ) external onlyMerchandiser whenNotPaused {
        require(products[productId].exist, "ShopManagement: product does not exist");
        require(amount > 0, "ShopManagement: amount must be greater than 0");
        require(price > 0, "ShopManagement: price must be greater than 0");

        products[productId].amount = amount;
        products[productId].price = price;

        emit ProductUpdated(productId, amount, price);
    }

    function buyProduct(uint256 productId) 
        external 
        onlyRole(STUDENT_ROLE) 
        whenNotPaused 
        nonReentrant 
    {
        Product storage product = products[productId];
        require(product.exist, "ShopManagement: product does not exist");
        require(product.amount > 0, "ShopManagement: product is out of stock");
        require(
            rewardsToken.transferFrom(msg.sender, address(this), product.price),
            "ShopManagement: transfer failed"
        );

        product.amount--;
        
        uint256 purchaseId = _purchaseCounter++;
        purchases[purchaseId] = Purchase({
            buyer: msg.sender,
            productId: productId,
            price: product.price,
            timeBuy: uint32(block.timestamp),
            timeReturn: 0,
            status: PurchaseStatus.COMPLETED
        });

        studentPurchases[msg.sender].push(purchaseId);
        emit ProductPurchased(productId, msg.sender, product.price);
    }

    function requestReturn(uint256 purchaseId) external whenNotPaused {
        Purchase storage purchase = purchases[purchaseId];
        require(purchase.buyer == msg.sender, "ShopManagement: not the buyer");
        require(purchase.status == PurchaseStatus.COMPLETED, "ShopManagement: invalid purchase status");

        purchase.status = PurchaseStatus.RETURN_REQUESTED;
    }

    function processReturn(uint256 purchaseId, bool approved) external onlyMerchandiser whenNotPaused {
        Purchase storage purchase = purchases[purchaseId];
        require(purchase.status == PurchaseStatus.RETURN_REQUESTED, "ShopManagement: invalid purchase status");

        if (approved) {
            require(
                rewardsToken.transfer(purchase.buyer, purchase.price),
                "ShopManagement: transfer failed"
            );
            products[purchase.productId].amount++;
            purchase.status = PurchaseStatus.RETURNED;
            emit PurchaseReturned(purchaseId, purchase.buyer);
        } else {
            purchase.status = PurchaseStatus.COMPLETED;
        }
    }

    function getProduct(uint256 productId) external view returns (Product memory) {
        return products[productId];
    }

    function getPurchase(uint256 purchaseId) external view returns (Purchase memory) {
        return purchases[purchaseId];
    }

    function getStudentPurchases(address student) external view returns (uint256[] memory) {
        return studentPurchases[student];
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
} 