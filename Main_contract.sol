// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.9.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol";

//  ПОЛЕЗНЫЕ ССЫЛКИ:
//  https://soliditydeveloper.com/max-contract-size
//  https://docs.soliditylang.org/en/v0.8.19/

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


contract Diplom is ERC20 {

// СТРУКТУРЫ И СПИСКИ ДАННЫХ
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    // Список ролей в системе
    enum Role { 
        student,
        teacher,
        merchandiser, 
        secretary,
        admin
    }

    // Структура пользователя
    struct User {
        string login;
        string phone;
        string email;
        string fio;
        bytes32 password;
        Role role;
        bool gender;
        bool online;
        bool exist;
    }

    // Структура товара
    struct Product {
        uint amount;
        uint price;
        string name;
        string description;
        Categoryes category;
        bool exist;
    }

    // Список категорий товаров в системе
    enum Categoryes {
        bakery,
        stationery,
        coupon
    }

    // Структура отзыва о товаре
    struct Review {
        address sender;
        uint product;
        string content;
        uint32 answer;
        uint32[] answers;
        uint8 rate;
        address[] likes;
        address[] dislikes;
        bool exists;
    }

    // Структура студента
    struct Student {
        string group;
        string speciality;
        uint cours;
        uint reward;
        uint[] achievements;
        uint[] myPurchases;
        uint[] myProducts;
        uint[] friends;
        uint32[] reviews; // отзывы
        string[] history;
    }

    // Структура покупки
    struct Purchase {
        address buyer;
        uint product;
        uint price;
        uint timeBuy;
        uint timeReturn;
        uint status; // 1 - отправлен запрос, 2 - подтвержден продавцом и ожидает студента, 3 - закончен, 4 - запрос на возврат товара, 5 - товар возвращен
    }

    // Структура подарка
    struct Gift {
        address sender;
        address recipient;
        uint value;
        string message;
        uint status; // 1 - send; 2 - принят; 3 - cancel
    }

    // Структура достижения
    struct Achievement {
        address owner;
        uint scale; // 4 - международные, 3 - всероссийские, 2 - областные, 1 - городские
        uint place; // 4 - 1 место, 3 - 2 место, 2 - 3 место, 1 - другое
        uint price; 
        string discription;
    }

    // Стуктура голосования
    struct Vote {
        address[] yes;
        address[] no;
        address[] voted;
        address[] rating;
        uint status; // 1 - голосуют; 2 - закончено; 3 - отклонено.
    }

    // Пользователи
    mapping (address => User) users;
    mapping (string => address) addresses;

    // Товары 
    mapping (uint => Product) products;
    uint productId = 4;
    
    // Отзывы о товарах
    mapping(uint32 => Review) reviews;
    uint32[] reviewsArray = [0];

    // Cтуденты
    address[] studentsArray;
    mapping (address => Student) students;

    // Покупки
    uint idPurchase = 0;
    mapping (uint => Purchase) purchases;
    
    // Подарки
    uint idGift = 0;
    mapping (uint => Gift) gifts;

    // Достижения
    uint achId = 0;
    mapping (uint => Achievement) achievements;
    
    // Голосования
    mapping (uint => Vote) votes;
    mapping (uint => address) forRating;
    uint public idVote = 1;

    // Админы
    address[] admins;

    // Время деплоя контракта
    uint start = 0;
    bool flagVote = false;
    uint countMounth = 1;





// ФУНКЦИОНАЛ ПОЛЬЗОВАТЕЛЯ
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    // Функция входа в аккаунт
    function logIn (bytes32 password) public {
        require(password == users[msg.sender].password && users[msg.sender].exist, "Wrong password or login");
        users[msg.sender].online = true;
    }

    function newUser (address addr, string memory login, string memory phone, string memory email, string memory fio, bytes32 password, Role role, bool gender) public {
        users[addr] = User(login, phone, email, fio, password, role, gender, false, true);
        addresses[login] = addr;
    }

    function newStudent (address addr, string memory group, string memory speciality, uint cours ) public {
        uint[]   memory U;
        uint32[] memory U2;
        string[] memory S;
        students[addr] = Student(group, speciality, cours + 1, 0, U, U, U, U, U2, S);
    }

    // Функция получение адреса
    function getAdrress (string memory login) public view returns (address) {
        return addresses[login];
    }

    // Функция получения информации об пользователе
    function getUser (address addr) public view returns (string memory, string memory, string memory, string memory, Role, bool, bool, bool) {
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






// ФУНКЦИОНАЛ СВЯЗАННЫЙ С ТОВАРАМИ
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    // Функция создания нового товара
    function createProduct (string memory name, string memory description, Categoryes category, uint amount, uint price) public {
        products[++productId] = Product(amount, price, name, description, category, true);
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
    function getProduct (uint id) public view returns(uint, uint, string memory, string memory, Categoryes, bool) {
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






// ФУНКЦИОНАЛ СТУДЕНТОВ // Пересмотреть покупку Товара  ???
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    // Функция подтверждения запроса на покупку от мерчандайзера 
    function acceptRequestBuy (uint id) public {
        purchases[id].status = 2;
    }

    function buyProduct (uint id) public {
        _transfer(msg.sender, 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, products[id].price);
        products[id].amount = products[id].amount - 1;
        students[msg.sender].myProducts.push(id);
        students[msg.sender].myPurchases.push(id);
        purchases[++idPurchase] = Purchase(msg.sender, id, products[id].price, 0, 0, 1);
        purchases[id].timeBuy = block.timestamp;
        purchases[id].status = 3;
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
            purchase.product,
            purchase.price,
            purchase.timeBuy,
            purchase.timeReturn,
            purchase.status
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
            student.cours,
            student.reward,
            student.myPurchases,
            student.myProducts,
            student.friends,
            student.history
        );
    }





// ФУНКЦИОНАЛ ВОЗНАГРАЖДЕНИЯ СТУДЕНТОВ
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    // Функция добавления достижения/грамоты студенту
    function addAchievement (address owner, uint scale, uint place, string memory discription) public {
        require(users[owner].role == Role.student, "Role user no students");
        uint price = scale * place;
        achievements[++achId] = Achievement(owner, scale, place, price, discription);
        students[owner].achievements.push(achId);
    }

    // Функция Получения информции о достижении
    function getAchievement (uint id) public view returns (address, uint, uint, uint, string memory) {
        Achievement memory ach = achievements[id];
        return( 
            ach.owner, 
            ach.scale, 
            ach.place, 
            ach.price, 
            ach.discription
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
    // Еще немного улучшить (добавить успеваемость в суммарные токены) и сделать вложенный маппинг, чтобы получать значение по uint и адресу студента
    function rating () private returns (address[] memory) {

        uint[] memory znahenia = new uint[](studentsArray.length);

        for (uint i = 0; i < studentsArray.length; i++) {
            if (users[studentsArray[i]].exist) {
                uint sumPriceAchiv = 0;

                for (uint j = 0; j < students[studentsArray[i]].achievements.length; j++) {
                    sumPriceAchiv += achievements[students[studentsArray[i]].achievements[j]].price;
                }

                if (sumPriceAchiv != 0) {
                    znahenia[i] = sumPriceAchiv;
                    forRating[sumPriceAchiv] = studentsArray[i];
                }
            }
        }
        znahenia = _sortArray(znahenia);
        address[] memory studRating = new address[](znahenia.length);

        for (uint i = 0; i < znahenia.length; i++) {
            studRating[i] = forRating[znahenia[i]];
            students[forRating[znahenia[i]]].reward = znahenia[i];
        }
        return (studRating);
    }

    function changeStateStudents() public {
         for (uint i = 0; i < studentsArray.length; i++) {
            students[studentsArray[i]].cours++;
            if (students[studentsArray[i]].cours == 5) {
                users[studentsArray[i]].exist = false;
                deleteUser(studentsArray[i]);
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
        addresses["Dima"] = 0x26b1FD93B9081934803A83D362EcD32c1C6E5C59;

            admins.push(0x26b1FD93B9081934803A83D362EcD32c1C6E5C59);

        // Студенты
        users[0xdEA0eCB71d6A6A6fa85427B4bFE88D6e67C4bdfb] = User("Anton", "89094340355", "0_acc@gmail.com", "Anton Silyanov", 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, Role.student, true, false, true);
        addresses["Anton"] = 0xdEA0eCB71d6A6A6fa85427B4bFE88D6e67C4bdfb;

            students[0xdEA0eCB71d6A6A6fa85427B4bFE88D6e67C4bdfb] = Student("P-419", "09.02.07", 4, 0, empU, empU, empU, empU, empR, empS);
            studentsArray.push(0xdEA0eCB71d6A6A6fa85427B4bFE88D6e67C4bdfb);

        // Учителя
        users[0x00a6b70fb75C7208297806a2a4c6ddf19D550d1D] = User("Vanya", "89094340355", "0_acc@gmail.com", "Vanya Leichenkov", 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, Role.teacher, true, false, true);
        addresses["Vanya"] = 0x00a6b70fb75C7208297806a2a4c6ddf19D550d1D;

        // Товаровед 
        users[0xa828E01796040D0Ad59De9601609790561AAAEfB] = User("Sergey", "89094340355", "0_acc@gmail.com", "Sergey Morgun", 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, Role.merchandiser, true, false, true);
        addresses["Sergey"] = 0xa828E01796040D0Ad59De9601609790561AAAEfB;
        
        // Секретарь 
        users[0x768ACd1608A85c9ab8b407255f846F74854c617a] = User("Maxim", "89094340355", "0_acc@gmail.com", "Maxim Stulov", 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, Role.secretary, true, false, true);
        addresses["Maxim"] = 0x768ACd1608A85c9ab8b407255f846F74854c617a;

        // Товары
        products[1] = Product(10, 150, "Bulochka",  "Vkusno", Categoryes.bakery, true);
        products[2] = Product(10, 250, "Pizza",     "Vkusno", Categoryes.bakery, true);
        products[3] = Product(10, 200, "Gamburger", "Vkusno", Categoryes.bakery, true);
        products[4] = Product(10, 300, "Coca cola", "Vkusno", Categoryes.bakery, true);
    }
}
