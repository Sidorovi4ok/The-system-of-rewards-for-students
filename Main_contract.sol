// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Библиотека для работы с массивами
library ArrayUtils {
    function removeElement(uint[] storage array, uint index) internal {
        require(index < array.length, "Index out of bounds");
        array[index] = array[array.length - 1];
        array.pop();
    }

    function removeAddress(address[] storage array, address addr) internal returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == addr) {
                array[i] = array[array.length - 1];
                array.pop();
                return true;
            }
        }
        return false;
    }
}

// Основной контракт
contract StudentRewards is ERC20, Pausable, AccessControl, ReentrancyGuard {
    using ArrayUtils for uint[];
    using ArrayUtils for address[];

    // Роли в системе
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TEACHER_ROLE = keccak256("TEACHER_ROLE");
    bytes32 public constant MERCHANDISER_ROLE = keccak256("MERCHANDISER_ROLE");
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");
    bytes32 public constant SECRETARY_ROLE = keccak256("SECRETARY_ROLE");

    // События
    event UserCreated(address indexed user, bytes32 role);
    event ProductCreated(uint indexed id, bytes32 name, uint32 price);
    event ProductPurchased(uint indexed id, address indexed buyer, uint32 price);
    event ProductReturned(uint indexed id, address indexed buyer);
    event AchievementAdded(address indexed student, uint8 scale, uint8 place);
    event VoteStarted(uint indexed voteId);
    event VoteEnded(uint indexed voteId, bool approved);
    event RewardDistributed(address indexed student, uint amount);

    // Структуры данных
    struct User {
        bytes32 login;
        bytes32 phone;
        bytes32 email;
        string fio;
        bytes32 password;
        bytes32 role;
        bool gender;
        bool online;
        bool exist;
    }

    struct Product {
        uint32 amount;
        uint32 price;
        bytes32 name;
        string description;
        Category category;
        bool exist;
    }

    enum Category {
        BAKERY,
        STATIONERY,
        COUPON
    }

    struct Achievement {
        address owner;
        uint8 scale;  // 4 - международные, 3 - всероссийские, 2 - областные, 1 - городские
        uint8 place;  // 4 - 1 место, 3 - 2 место, 2 - 3 место, 1 - другое
        uint32 price;
        string description;
    }

    struct Student {
        bytes32 group;
        bytes32 speciality;
        uint8 course;
        uint32 reward;
        uint[] achievements;
        uint[] purchases;
        uint[] products;
        address[] friends;
        uint32[] reviews;
        string[] history;
    }

    struct Purchase {
        address buyer;
        uint productId;
        uint32 price;
        uint32 timeBuy;
        uint32 timeReturn;
        PurchaseStatus status;
    }

    enum PurchaseStatus {
        REQUESTED,
        CONFIRMED,
        COMPLETED,
        RETURN_REQUESTED,
        RETURNED
    }

    // Структура для рейтинга
    struct Rating {
        address student;
        uint32 score;
    }

    // Маппинги и массивы
    mapping(address => User) private users;
    mapping(bytes32 => address) private loginToAddress;
    mapping(uint => Product) private products;
    mapping(uint => Achievement) private achievements;
    mapping(address => Student) private students;
    mapping(uint => Purchase) private purchases;
    
    // Счетчики
    uint private productId;
    uint private achievementId;
    uint private purchaseId;
    
    // Массивы для быстрого доступа
    address[] private studentAddresses;
    uint[] private productIds;
    
    // Константы
    uint32 private constant MAX_PRODUCT_AMOUNT = type(uint32).max;
    uint32 private constant MIN_PRODUCT_PRICE = 1;
    uint8 private constant MAX_COURSE = 4;
    
    // Модификаторы
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "Caller does not have required role");
        _;
    }

    modifier userExists(address addr) {
        require(users[addr].exist, "User does not exist");
        _;
    }

    modifier productExists(uint id) {
        require(products[id].exist, "Product does not exist");
        _;
    }

    modifier studentExists(address addr) {
        require(users[addr].exist && hasRole(STUDENT_ROLE, addr), "Student does not exist");
        _;
    }

    // Конструктор
    constructor(
        string memory name,
        string memory symbol,
        address admin
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(ADMIN_ROLE, admin);
    }

    // Функция сортировки массива
    function _sortArray(uint[] memory array) pure returns (uint [] memory) {
        uint[] memory arr = new uint[] (array.length);
        for (uint i = 0; i < array.length; i++) {
            arr[i] = array[i];
        }
        for (uint i = 0; i < array.length; i++) {
            for (uint j = i+1; j < array.length; j++) {
                if (arr[i] < arr[j]) {
                    uint temp = arr[j];
                    arr[j] = arr[i];
                    arr[i] = temp;
                }
            }
        }
        return arr;
    }

    // Функция входа в аккаунт
    function logIn (bytes32 password) public {
        require(password == users[msg.sender].password && users[msg.sender].exist, "Wrong password or login");
        users[msg.sender].online = true;
    }

    function newUser (address addr, string memory login, string memory phone, string memory email, string memory fio, bytes32 password, bytes32 role, bool gender) public {
        users[addr] = User(login, phone, email, fio, password, role, gender, false, true);
        loginToAddress[login] = addr;
    }

    function newStudent (address addr, string memory group, string memory speciality, uint cours ) public {
        uint[]   memory U;
        uint32[] memory U2;
        string[] memory S;
        students[addr] = Student(group, speciality, cours + 1, 0, U, U, U, U, U2, S);
    }

    // Функция получение адреса
    function getAdrress (string memory login) public view returns (address) {
        return loginToAddress[login];
    }

    // Функция получения информации об пользователе
    function getUser (address addr) public view returns (string memory, string memory, string memory, string memory, bytes32, bool, bool, bool) {
        User memory user = users[addr];
        return (
            user.login,
            user.phone,
            user.email,
            user.fio,
            user.role,
            user.gender,
            user.online,
            user.exist
        );
    }

    // Функция выхода из аккаунта
    function logOut () public {
        require(users[msg.sender].exist, "User dont exist");
        users[msg.sender].online = false;
    }

    // Функция удаления аккаунта пользователя
    function deleteUser (address addr) public {
        users[addr].exist = false;
    }

    // Функция создания нового товара
    function createProduct(
        bytes32 name,
        string memory description,
        Category category,
        uint32 amount,
        uint32 price
    ) public onlyRole(MERCHANDISER_ROLE) {
        require(amount > 0, "Amount must be greater than 0");
        require(price > 0, "Price must be greater than 0");

        unchecked {
            productId++;
        }

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

    // Функция добавления количества уже существующего товара
    function addProduct (uint id, uint amount) public {
        products[id].amount += amount;
    }

    // Функция удаления товара
    function deleteProduct (uint id) public {
        products[id].exist = false;
    }

    // Функция оставления отзыва товару
    function newReview (uint product, string memory content, uint8 rate, uint32 answer) public {
        require(rate >= 1 && rate <= 10, "Rate can only be between 1 and 10");
        uint32 reviewId = uint32(reviewsArray.length);
        reviewsArray.push(reviewId);

        if (answer != 0) {
            reviews[answer].answers.push(reviewId);
        }

        uint32[] memory emptyReviews;
        address[] memory emptyAddresses;

        reviews[reviewId] = Review(msg.sender, product, content, answer, emptyReviews, rate, emptyAddresses, emptyAddresses, true);
        students[msg.sender].reviews.push(reviewId);
    }

    // Функция получения отзывов о товаре
    function getProductReviews (uint product) public view returns (uint32[] memory reviewIds) {
        uint32 count;
        uint32[] memory rawReviews = new uint32[](reviewsArray.length);

        for (uint256 i = 0; i < reviewsArray.length; i++) {
            if (reviews[reviewsArray[i]].product == product) {
                rawReviews[count] = reviewsArray[i];
                count++;
            }
        }

        reviewIds = new uint32[](count);
        for (uint256 i = 0; i < count; i++) {
            reviewIds[i] = rawReviews[i];
        }
        return reviewIds;
    }

    // Функция получения всей информации о отзыве
    function getReview (uint32 reviewId) public view returns (bool, address, uint, string memory,uint32, uint32[] memory, uint8, address[] memory, address[] memory) {
        Review memory review = reviews[reviewId];
        return (
            review.exists,
            review.sender,
            review.product,
            review.content,
            review.answer,
            review.answers,
            review.rate,
            review.likes,
            review.dislikes
        );
    }

    // Функция получения всей информации о товаре
    function getProduct (uint id) public view returns(uint, uint, string memory, string memory, Category, bool) {
        Product memory product = products[id];
        return (
            product.amount,
            product.price,
            product.name,
            product.description,
            product.category,
            product.exist
        );
    }

    // Функция подтверждения запроса на покупку от мерчандайзера 
    function acceptRequestBuy (uint id) public {
        purchases[id].status = CONFIRMED;
    }

    function buyProduct(uint id) public onlyRole(STUDENT_ROLE) userExists(msg.sender) {
        require(products[id].exist, "Product does not exist");
        require(products[id].amount > 0, "Product is out of stock");
        require(balanceOf(msg.sender) >= products[id].price, "Insufficient balance");

        unchecked {
            products[id].amount--;
        }

        _transfer(msg.sender, 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, products[id].price);
        
        students[msg.sender].myProducts.push(id);
        students[msg.sender].myPurchases.push(id);
        
        uint purchaseId = ++purchaseId;
        purchases[purchaseId] = Purchase({
            buyer: msg.sender,
            productId: id,
            price: products[id].price,
            timeBuy: uint32(block.timestamp),
            timeReturn: 0,
            status: CONFIRMED
        });

        emit ProductPurchased(id, msg.sender, products[id].price);
    }

    // Функция запроса на возврат 
    function sendRequestReturn (uint idProd) public {
        idReturn++;
        returned[idReturn] = Return(msg.sender, idProd, true, idReturn);
    }

    struct Return {
        address buyer;
        uint product;
        bool status;
        uint id;
    }

    mapping (uint => Return) returned;
    uint idReturn = 0;

    function getRefundProduct (uint id) public view returns(address, uint, bool, uint){
        return(
            returned[id].buyer,
            returned[id].product,
            returned[id].status,
            returned[id].id
        );
    }

    // Функция подтверждения возврата товара 
    function acceptRequestReturn (uint id) public {
        _transfer(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, returned[id].buyer, products[returned[id].product].price);
        for (uint i = 0; i < students[returned[id].buyer].myProducts.length; i++) {
            if (students[returned[id].buyer].myProducts[i] == returned[id].product) {
                delete students[returned[id].buyer].myProducts[i];
                products[returned[id].product].amount =  products[returned[id].product].amount + 1;
                break;
            }
        }
        returned[id].status = false;
    }

    // Функция отправки подарка другу 
    function sendGift (address addr, uint value, string memory message) public {
        // + Провекра что получатель - твой друг
        gifts[++idGift] = Gift(msg.sender, addr, value, message, 1);
        _transfer(msg.sender, 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, value);
        // + Какая то комиссия системе и ограничить количество максимально подаренных токенов
    }

    // Возможно обьединить в одну функцию - ответ на подарок
    // Функция принятия подарка от друга 
    function acceptGift (uint id) public {
        // Проверка что подарок именно для тебя ???
        _transfer(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, msg.sender, gifts[id].value);
        gifts[id].status = 2;
    }

    // Функция отмены подарка от друга 
    function cancelGift (uint id) public {
        // Проверка что подарок именно для тебя ???
        _transfer(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, msg.sender, gifts[id].value);
        gifts[id].status = 3;
    }

    // Функция порлучения всех отзывов от студента
    function _getStudentReviews(address addr) public view returns (uint32[] memory reviewIds) {
        return (students[addr].reviews);
    }

    // Функция получения информации о покупке товара 
    function getPurchase (uint id) public view returns (address, uint, uint, uint, uint, uint) {
        Purchase memory purchase = purchases[id];
        return(
            purchase.buyer,
            purchase.productId,
            purchase.price,
            purchase.timeBuy,
            purchase.timeReturn,
            uint(purchase.status)
        );
    }

    // Функция получения информации о покупке подарке
    function getGift (uint id) public view returns (address, address, uint, string memory, uint) {
        Gift memory gift = gifts[id];
        return(
            gift.sender,
            gift.recipient,
            gift.value,
            gift.message,
            gift.status
        );
    }
    
    // Функция получения информации о студенте
    function getStudent (address addr) public view returns (string memory, string memory, uint, uint, uint[] memory, uint[] memory, uint[] memory, string[] memory) {
        Student memory student = students[addr];
        return (
            student.group,
            student.speciality,
            student.course,
            student.reward,
            student.myPurchases,
            student.myProducts,
            student.friends,
            student.history
        );
    }

    // Функция добавления достижения/грамоты студенту
    function addAchievement (address owner, uint scale, uint place, string memory discription) public {
        require(hasRole(STUDENT_ROLE, owner), "Role user no students");
        uint price = scale * place;
        achievements[++achievementId] = Achievement(owner, uint8(scale), uint8(place), price, discription);
        students[owner].achievements.push(achievementId);
    }

    // Функция Получения информции о достижении
    function getAchievement (uint id) public view returns (address, uint, uint, uint, string memory) {
        Achievement memory ach = achievements[id];
        return( 
            ach.owner, 
            ach.scale, 
            ach.place, 
            ach.price, 
            ach.description
        );
    }

    // Функция начала голосования
    function voting () public {
        if( !flagVote ) {
            address[] memory emptyArray_a;
            mounth++;
            votes[idVote] = Vote(emptyArray_a, emptyArray_a, emptyArray_a, emptyArray_a, 1);
            emptyArray_a = rating();
            votes[idVote].rating = emptyArray_a;
            flagVote = true;
        }
    }

    function getFlagVote() public view returns(bool) {
        return flagVote;
    }

    // Функция получения информации о голосовании
    function getVote (uint id) public view returns (address[] memory, address[] memory, address[] memory, uint) {
        Vote memory vote = votes[id];
        return (
            vote.yes, 
            vote.no, 
            vote.rating, 
            vote.status
        );
    }

    // Функция голосования для админов 
    function setVote (bool choice) public {
        for(uint i = 0; i < votes[idVote].voted.length; i++) {
            require(votes[idVote].voted[i] != msg.sender, "You are voting");
        }
        votes[idVote].voted.push(msg.sender);

        if (choice) {
            votes[idVote].yes.push(msg.sender);
        } else {
            votes[idVote].no.push(msg.sender);
        }

        if (votes[idVote].voted.length == admins.length) {
            if (votes[idVote].yes.length > votes[idVote].no.length) {
                for (uint i = 0; i < votes[idVote].rating.length; i++) {
                    _transfer(0x26b1FD93B9081934803A83D362EcD32c1C6E5C59, votes[idVote].rating[i], students[votes[idVote].rating[i]].reward);
                }
                votes[idVote].status = 2;
                flagVote = false;
                idVote++;
                countMounth++;
            } 
            else {
                // что-то мб
                votes[idVote].status = 3;
                flagVote = false;
                idVote++;
                countMounth++;
            }
        }
    }
    
    // Функция составления рейтинга
    function rating() private returns (address[] memory) {
        uint activeStudents = 0;
        
        // Подсчитываем количество активных студентов
        for (uint i = 0; i < studentAddresses.length; i++) {
            if (users[studentAddresses[i]].exist) {
                activeStudents++;
            }
        }

        // Создаем массивы нужного размера
        uint[] memory scores = new uint[](activeStudents);
        address[] memory activeAddresses = new address[](activeStudents);
        uint currentIndex = 0;

        // Заполняем массивы только активными студентами
        for (uint i = 0; i < studentAddresses.length; i++) {
            if (users[studentAddresses[i]].exist) {
                uint sumPriceAchiv = 0;
                uint[] memory studentAchievements = students[studentAddresses[i]].achievements;
                
                // Используем unchecked для оптимизации gas
                unchecked {
                    for (uint j = 0; j < studentAchievements.length; j++) {
                        sumPriceAchiv += achievements[studentAchievements[j]].price;
                    }
                }

                if (sumPriceAchiv > 0) {
                    scores[currentIndex] = sumPriceAchiv;
                    activeAddresses[currentIndex] = studentAddresses[i];
                    forRating[sumPriceAchiv] = studentAddresses[i];
                    currentIndex++;
                }
            }
        }

        // Сортировка массива
        for (uint i = 0; i < activeStudents - 1; i++) {
            for (uint j = i + 1; j < activeStudents; j++) {
                if (scores[i] < scores[j]) {
                    // Обмен значениями
                    uint tempScore = scores[i];
                    address tempAddr = activeAddresses[i];
                    
                    scores[i] = scores[j];
                    activeAddresses[i] = activeAddresses[j];
                    
                    scores[j] = tempScore;
                    activeAddresses[j] = tempAddr;
                }
            }
        }

        // Обновляем награды студентов
        for (uint i = 0; i < activeStudents; i++) {
            students[activeAddresses[i]].reward = scores[i];
        }

        return activeAddresses;
    }

    function changeStateStudents() public {
         for (uint i = 0; i < studentAddresses.length; i++) {
            students[studentAddresses[i]].course++;
            if (students[studentAddresses[i]].course == 5) {
                users[studentAddresses[i]].exist = false;
                deleteUser(studentAddresses[i]);
            }
        }
    }

    function nextCours() public returns (bool) {
        if (mounth == 12) {
            mounth = 1;
            return true;
        }
        return false;
    }
    
    uint8 mounth = 1;
    // Функция проверки прошел ли месяц - для начала голосования
    function checkMonth () public view returns (bool) {
        if (block.timestamp > start + 30 days * countMounth) {
            return true;
        }
        else {
            return false;
        }
    }

    function peremotka(uint month) public{
        start = start - 30 days * month;
    }

    // Конструктор контракта
    constructor (string memory name, string memory symbol) ERC20(name, symbol) 
    {
        // Пустые массивы для заполнения структур 
        uint[]   memory empU;
        string[] memory empS;
        uint32[] memory empR;

        // Определение времени деплоя контракта
        start = block.timestamp;

        // Чеканка токенов - 1 token = 1 * (10 ** decimals)
        _mint(msg.sender, 100000 * 10**uint(decimals()));

        _transfer(msg.sender, 0xdEA0eCB71d6A6A6fa85427B4bFE88D6e67C4bdfb, 10000);

        // Администраторы 
        users[0x26b1FD93B9081934803A83D362EcD32c1C6E5C59] = User("Dima", "89094340355", "0_acc@gmail.com", "Dima Kononenko", 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, Role.admin, true, false, true);
        loginToAddress["Dima"] = 0x26b1FD93B9081934803A83D362EcD32c1C6E5C59;

            admins.push(0x26b1FD93B9081934803A83D362EcD32c1C6E5C59);

        // Студенты
        users[0xdEA0eCB71d6A6A6fa85427B4bFE88D6e67C4bdfb] = User("Anton", "89094340355", "0_acc@gmail.com", "Anton Silyanov", 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, Role.student, true, false, true);
        loginToAddress["Anton"] = 0xdEA0eCB71d6A6A6fa85427B4bFE88D6e67C4bdfb;

            students[0xdEA0eCB71d6A6A6fa85427B4bFE88D6e67C4bdfb] = Student("P-419", "09.02.07", 4, 0, empU, empU, empU, empU, empR, empS);
            studentAddresses.push(0xdEA0eCB71d6A6A6fa85427B4bFE88D6e67C4bdfb);

        // Учителя
        users[0x00a6b70fb75C7208297806a2a4c6ddf19D550d1D] = User("Vanya", "89094340355", "0_acc@gmail.com", "Vanya Leichenkov", 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, Role.teacher, true, false, true);
        loginToAddress["Vanya"] = 0x00a6b70fb75C7208297806a2a4c6ddf19D550d1D;

        // Товаровед 
        users[0xa828E01796040D0Ad59De9601609790561AAAEfB] = User("Sergey", "89094340355", "0_acc@gmail.com", "Sergey Morgun", 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, Role.merchandiser, true, false, true);
        loginToAddress["Sergey"] = 0xa828E01796040D0Ad59De9601609790561AAAEfB;
        
        // Секретарь 
        users[0x768ACd1608A85c9ab8b407255f846F74854c617a] = User("Maxim", "89094340355", "0_acc@gmail.com", "Maxim Stulov", 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, Role.secretary, true, false, true);
        loginToAddress["Maxim"] = 0x768ACd1608A85c9ab8b407255f846F74854c617a;

        // Товары
        products[1] = Product(10, 150, "Bulochka",  "Vkusno", Category.BAKERY, true);
        products[2] = Product(10, 250, "Pizza",     "Vkusno", Category.BAKERY, true);
        products[3] = Product(10, 200, "Gamburger", "Vkusno", Category.BAKERY, true);
        products[4] = Product(10, 300, "Coca cola", "Vkusno", Category.BAKERY, true);
    }

    // Функции управления пользователями
    function createUser(
        address addr,
        bytes32 login,
        bytes32 phone,
        bytes32 email,
        string memory fio,
        bytes32 password,
        bytes32 role,
        bool gender
    ) external onlyRole(ADMIN_ROLE) {
        require(addr != address(0), "Invalid address");
        require(!users[addr].exist, "User already exists");
        require(loginToAddress[login] == address(0), "Login already taken");

        users[addr] = User({
            login: login,
            phone: phone,
            email: email,
            fio: fio,
            password: password,
            role: role,
            gender: gender,
            online: false,
            exist: true
        });

        loginToAddress[login] = addr;
        _setupRole(role, addr);

        emit UserCreated(addr, role);
    }

    function createStudent(
        address addr,
        bytes32 group,
        bytes32 speciality,
        uint8 course
    ) external onlyRole(ADMIN_ROLE) {
        require(hasRole(STUDENT_ROLE, addr), "Address must have student role");
        require(course <= MAX_COURSE, "Invalid course number");

        students[addr] = Student({
            group: group,
            speciality: speciality,
            course: course,
            reward: 0,
            achievements: new uint[](0),
            purchases: new uint[](0),
            products: new uint[](0),
            friends: new address[](0),
            reviews: new uint32[](0),
            history: new string[](0)
        });

        studentAddresses.push(addr);
    }

    function login(bytes32 password) external {
        require(users[msg.sender].exist, "User does not exist");
        require(users[msg.sender].password == password, "Invalid password");
        users[msg.sender].online = true;
    }

    function logout() external {
        require(users[msg.sender].exist, "User does not exist");
        users[msg.sender].online = false;
    }

    function updateUserProfile(
        bytes32 phone,
        bytes32 email,
        string memory fio
    ) external userExists(msg.sender) {
        users[msg.sender].phone = phone;
        users[msg.sender].email = email;
        users[msg.sender].fio = fio;
    }

    function changePassword(bytes32 newPassword) external userExists(msg.sender) {
        users[msg.sender].password = newPassword;
    }

    // Функции для работы с товарами
    function createProduct(
        bytes32 name,
        string memory description,
        Category category,
        uint32 amount,
        uint32 price
    ) external onlyRole(MERCHANDISER_ROLE) whenNotPaused {
        require(amount > 0 && amount <= MAX_PRODUCT_AMOUNT, "Invalid amount");
        require(price >= MIN_PRODUCT_PRICE, "Invalid price");

        unchecked {
            productId++;
        }

        products[productId] = Product({
            amount: amount,
            price: price,
            name: name,
            description: description,
            category: category,
            exist: true
        });

        productIds.push(productId);
        emit ProductCreated(productId, name, price);
    }

    function updateProduct(
        uint id,
        uint32 amount,
        uint32 price
    ) external onlyRole(MERCHANDISER_ROLE) productExists(id) {
        require(amount <= MAX_PRODUCT_AMOUNT, "Invalid amount");
        require(price >= MIN_PRODUCT_PRICE, "Invalid price");

        products[id].amount = amount;
        products[id].price = price;
    }

    function buyProduct(uint id) 
        external 
        onlyRole(STUDENT_ROLE) 
        studentExists(msg.sender) 
        productExists(id) 
        whenNotPaused 
        nonReentrant 
    {
        Product storage product = products[id];
        require(product.amount > 0, "Product out of stock");
        require(balanceOf(msg.sender) >= product.price, "Insufficient balance");

        unchecked {
            product.amount--;
        }

        _transfer(msg.sender, address(this), product.price);
        
        Student storage student = students[msg.sender];
        student.products.push(id);
        
        unchecked {
            purchaseId++;
        }
        
        purchases[purchaseId] = Purchase({
            buyer: msg.sender,
            productId: id,
            price: product.price,
            timeBuy: uint32(block.timestamp),
            timeReturn: 0,
            status: PurchaseStatus.COMPLETED
        });

        student.purchases.push(purchaseId);
        emit ProductPurchased(id, msg.sender, product.price);
    }

    // Функции для работы с достижениями
    function addAchievement(
        address student,
        uint8 scale,
        uint8 place,
        string memory description
    ) external onlyRole(TEACHER_ROLE) studentExists(student) {
        require(scale >= 1 && scale <= 4, "Invalid scale");
        require(place >= 1 && place <= 4, "Invalid place");

        uint32 price = uint32(scale * place);
        
        unchecked {
            achievementId++;
        }

        achievements[achievementId] = Achievement({
            owner: student,
            scale: scale,
            place: place,
            price: price,
            description: description
        });

        students[student].achievements.push(achievementId);
        emit AchievementAdded(student, scale, place);
    }

    // Вспомогательные функции
    function getUser(address addr) external view returns (
        bytes32 login,
        bytes32 phone,
        bytes32 email,
        string memory fio,
        bytes32 role,
        bool gender,
        bool online,
        bool exist
    ) {
        User memory user = users[addr];
        return (
            user.login,
            user.phone,
            user.email,
            user.fio,
            user.role,
            user.gender,
            user.online,
            user.exist
        );
    }

    function getStudent(address addr) external view returns (
        bytes32 group,
        bytes32 speciality,
        uint8 course,
        uint32 reward,
        uint[] memory achievements,
        uint[] memory purchases,
        uint[] memory products
    ) {
        Student memory student = students[addr];
        return (
            student.group,
            student.speciality,
            student.course,
            student.reward,
            student.achievements,
            student.purchases,
            student.products
        );
    }

    function getProduct(uint id) external view returns (
        uint32 amount,
        uint32 price,
        bytes32 name,
        string memory description,
        Category category,
        bool exist
    ) {
        Product memory product = products[id];
        return (
            product.amount,
            product.price,
            product.name,
            product.description,
            product.category,
            product.exist
        );
    }

    // Функции управления контрактом
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function grantRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    // Функции для работы с рейтингом и вознаграждениями
    function calculateStudentScore(address student) public view returns (uint32) {
        Student storage studentData = students[student];
        uint32 totalScore = 0;

        for (uint i = 0; i < studentData.achievements.length; i++) {
            Achievement storage achievement = achievements[studentData.achievements[i]];
            totalScore += achievement.price;
        }

        return totalScore;
    }

    function updateStudentRewards() external onlyRole(ADMIN_ROLE) {
        Rating[] memory ratings = new Rating[](studentAddresses.length);
        uint validStudents = 0;

        // Собираем оценки всех активных студентов
        for (uint i = 0; i < studentAddresses.length; i++) {
            address studentAddr = studentAddresses[i];
            if (users[studentAddr].exist && hasRole(STUDENT_ROLE, studentAddr)) {
                uint32 score = calculateStudentScore(studentAddr);
                if (score > 0) {
                    ratings[validStudents] = Rating(studentAddr, score);
                    validStudents++;
                }
            }
        }

        // Сортировка рейтинга
        for (uint i = 0; i < validStudents - 1; i++) {
            for (uint j = i + 1; j < validStudents; j++) {
                if (ratings[i].score < ratings[j].score) {
                    Rating memory temp = ratings[i];
                    ratings[i] = ratings[j];
                    ratings[j] = temp;
                }
            }
        }

        // Распределение вознаграждений
        for (uint i = 0; i < validStudents; i++) {
            address studentAddr = ratings[i].student;
            uint32 reward = ratings[i].score;
            
            students[studentAddr].reward = reward;
            _transfer(address(this), studentAddr, reward);
            
            emit RewardDistributed(studentAddr, reward);
        }
    }

    function getTopStudents(uint limit) external view returns (address[] memory, uint32[] memory) {
        Rating[] memory ratings = new Rating[](studentAddresses.length);
        uint validStudents = 0;

        // Собираем оценки
        for (uint i = 0; i < studentAddresses.length; i++) {
            address studentAddr = studentAddresses[i];
            if (users[studentAddr].exist && hasRole(STUDENT_ROLE, studentAddr)) {
                uint32 score = calculateStudentScore(studentAddr);
                if (score > 0) {
                    ratings[validStudents] = Rating(studentAddr, score);
                    validStudents++;
                }
            }
        }

        // Сортировка
        for (uint i = 0; i < validStudents - 1; i++) {
            for (uint j = i + 1; j < validStudents; j++) {
                if (ratings[i].score < ratings[j].score) {
                    Rating memory temp = ratings[i];
                    ratings[i] = ratings[j];
                    ratings[j] = temp;
                }
            }
        }

        // Подготовка результата
        uint resultSize = limit > validStudents ? validStudents : limit;
        address[] memory topStudents = new address[](resultSize);
        uint32[] memory topScores = new uint32[](resultSize);

        for (uint i = 0; i < resultSize; i++) {
            topStudents[i] = ratings[i].student;
            topScores[i] = ratings[i].score;
        }

        return (topStudents, topScores);
    }

    function getStudentAchievements(address student) 
        external 
        view 
        studentExists(student) 
        returns (
            uint[] memory achievementIds,
            uint8[] memory scales,
            uint8[] memory places,
            uint32[] memory prices,
            string[] memory descriptions
        ) 
    {
        Student storage studentData = students[student];
        uint achievementCount = studentData.achievements.length;

        achievementIds = new uint[](achievementCount);
        scales = new uint8[](achievementCount);
        places = new uint8[](achievementCount);
        prices = new uint32[](achievementCount);
        descriptions = new string[](achievementCount);

        for (uint i = 0; i < achievementCount; i++) {
            uint achievementId = studentData.achievements[i];
            Achievement storage achievement = achievements[achievementId];
            
            achievementIds[i] = achievementId;
            scales[i] = achievement.scale;
            places[i] = achievement.place;
            prices[i] = achievement.price;
            descriptions[i] = achievement.description;
        }

        return (achievementIds, scales, places, prices, descriptions);
    }

    // Функция для перевода курса
    function advanceCourse() external onlyRole(ADMIN_ROLE) {
        for (uint i = 0; i < studentAddresses.length; i++) {
            address studentAddr = studentAddresses[i];
            Student storage student = students[studentAddr];
            
            if (users[studentAddr].exist && hasRole(STUDENT_ROLE, studentAddr)) {
                if (student.course < MAX_COURSE) {
                    student.course++;
                } else {
                    // Выпускник
                    _revokeRole(STUDENT_ROLE, studentAddr);
                    users[studentAddr].exist = false;
                }
            }
        }
    }
}
