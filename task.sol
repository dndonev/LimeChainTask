// SPDX-License-Identifier: FMI, Introduction to BlockChain 2021
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

contract Library {
    uint public RENT_PRICE = 5;
    bytes32 constant NULL = '';

    struct Book {
        string title;
        string author;
        bytes32 id;
        bytes32 internalId;
    }

    modifier isOwner() {
        require(msg.sender == owner, 'Caller is not owner');
        _;
    }

    event RentPriceChanged(uint oldPrice, uint newPrice);
    event BookBorrowed(address id);
    event BookAdded(bytes32 id, string title);
    event BookReturnedByBorrower(address id);

    address payable private owner;
    mapping(bytes32 => Book[]) private books;
    mapping(address => bytes32) private borrowers;
    Book[] private catalogue;

    constructor() {
        owner = msg.sender;
        emit RentPriceChanged(0, RENT_PRICE);
    }

    /**
     * @dev Add a new book to the library.
     * @param title - the book's title.
     * @param author - the book's author.
     */
    function addBook(string memory title, string memory author) public isOwner {
        pushNewBook(title, author);
    }
    
    /**
     * @dev Add book copies to the library.
     * @param id - book's id.
     * @param numberOfCopies - number of copies to add.
     */
    function addCopies(bytes32 id, uint numberOfCopies) external isOwner {
        require(numberOfCopies > 0, 'The number of copies must be more than 0');
        require(books[id].length > 0, 'Book does not exist');
        
        Book memory book = books[id][0];
        for (uint256 index = 0; index <= numberOfCopies; index++) {
            pushNewBook(book.author, book.title);
        }
    }

    /**
     * @dev Library lends a book.
     * @param id - the id of the demanded book.
     */
    function rentBook(bytes32 id) external payable {
        require(books[id].length >= 1, 'No copies left of the book');
        require(borrowers[msg.sender] != id, 'You are not allowed to rent more than one book.');
        uint256 value = msg.value;

        if (value == RENT_PRICE) {
            books[id].pop();
            if (books[id].length == 0) {
                removeFromCatalogue(id);
            }
            emit BookBorrowed(msg.sender);
            owner.transfer(value);
        }
    }
    
    /**
     * @dev Get available books.
     */
    function getBookCatalogue() external view returns (Book[] memory) {
        require(catalogue.length != 0, 'No books available');
        return catalogue;
    }
    
    /**
     * @dev Return book to the library.
     * @param title - the book's title.
     * @param author - the book's author.
     */
    function returnBook(string memory title, string memory author) external {
        require(borrowers[msg.sender] != 0);
        delete borrowers[msg.sender];
        emit BookReturnedByBorrower(msg.sender);
        pushNewBook(title, author);
    }
    
    /**
     * @dev Change library's rent price.
     * @param newRentPrice - the new rent price.
     */
    function changeRent(uint newRentPrice) external isOwner {
        require(newRentPrice > 0, 'You should be making money');

        uint oldRentPrice = RENT_PRICE;
        RENT_PRICE = newRentPrice;
        
        emit RentPriceChanged(oldRentPrice, RENT_PRICE);
    }

    /**
     * @dev Helper function to push a new book.
     * @param title - book's title.
     * @param author - book's author.
     */
    function pushNewBook(
        string memory title,
        string memory author
    ) private {
        bytes32 id = keccak256(abi.encodePacked(title, author));
        bytes32 internalId = keccak256(abi.encodePacked(title, author, id));

        Book memory newBook =
            Book({
                title: title,
                author: author,
                id: id,
                internalId: internalId
            });

        if (books[id].length == 0) {
            catalogue.push(newBook);
        }
        
        books[id].push(newBook);
        emit BookAdded(newBook.id, newBook.title);
    }
    
    /**
     * @dev Helper function to get a book by title from catalogue.
     * @param title - book's title.
     */
    function getBookByTitle(string memory title) private view returns (Book memory) {
        Book memory book;
        for (uint256 index = 0; index < catalogue.length; index++) {
            
            if (keccak256(abi.encodePacked((catalogue[index].title))) == keccak256(abi.encodePacked((title)))) {
                book = catalogue[index]; 
            }
        }
        
        return book;
    }
    
    /**
     * @dev Helper function to get a book by title from catalogue.
     * @param id - book's id.
     */
    function getBookIndexById(bytes32 id) private view returns (uint256) {
        uint256 catalogueIndex;
        for (uint256 index = 0; index < catalogue.length; index++) {
            
            if (catalogue[index].id == id) {
                catalogueIndex = index; 
            }
        }
        
        return catalogueIndex;
    }
    
    /**
     * @dev Helper function to delete a book by id from catalogue.
     * @param id - book's id.
     */
    function removeFromCatalogue(bytes32 id) private returns (bool) {
        uint256 index = getBookIndexById(id);
        if (index < 0 || index >= catalogue.length) {
            return false;
        } else if(catalogue.length == 1) {
            catalogue.pop();
            return true;
        } else if (index == catalogue.length - 1) {
            catalogue.pop();
            return true;
        } else {
            for (uint i = index; i < catalogue.length - 1; i++) {
                catalogue[i] = catalogue[i + 1];
            }
            
            catalogue.pop();
            return true;
        }
    }
}
