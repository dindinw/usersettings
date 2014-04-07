/*
 * A node.js script to rename a ebook file by given isdn.

 * Google Book API:
 * https://www.googleapis.com/books/v1/volumes?q=isbn:<your_isbn_here>
 * https://www.googleapis.com/books/v1/volumes?q=isbn:1617290572
 */
'use strict'; //strict mode 
var request = require('request');
var fs = require('fs');
var path = require('path');
var echo = console.log;

/* Consts*/
var BOOK_SAVE_PATH="C:\\Users\\yidwu\\Downloads\\_Un"
var ISBN_REGXP="^\d{9}[\d|X]$"

function requestByIsbn(bookNameCallback,isbn){
    var _bookname=""
    var reqBody = {
        method:'GET',
        uri: 'https://www.googleapis.com/books/v1/volumes?q=isbn:' + isbn
    };
    request(reqBody,function(err,rep,body){
        if(rep.statusCode == 200){
            
            var jsObject = JSON.parse(body);
            echo(reqBody.uri)
            
            var newName = "";
            var title=jsObject.items[0].volumeInfo.title;
            newName+=title+", "
            
            var subtitle=jsObject.items[0].volumeInfo.subtitle
            if (subtitle != undefined) newName += subtitle+", ";
            
            var date=jsObject.items[0].volumeInfo.publishedDate;
            newName += date.substr(0,4)+", ";
            
            echo("Title:",title);
            echo("subTitle:",subtitle)
            echo("Date:" ,date);
            
            newName += isbn
            bookNameCallback(newName);
        }else{
            echo('error :',rep.statusCode);
            echo(body);

        } 
    });
}



function parseIsdn(nameStr){
    var isbn = nameStr
    echo(nameStr,"->",isbn)
    return isbn
}

//requestByIsbn(doBookName,'1617290572');   

function renameBookNames(err,files){
    
    for (var i = 0; i<files.length ; i++){
        var fileName=files[i];
        var fileExt=path.extname(fileName);
        var fileBaseName=path.basename(fileName,fileExt);
        var fileIsbn=parseIsdn(fileBaseName);
        var doBookName = function changeName(newName){
            echo(fileName,newName)
        }
        requestByIsbn(doBookName,fileIsbn);   
    }

}

fs.readdir(BOOK_SAVE_PATH,renameBookNames);