package com.appsdeveloperblog.photoapp.api.account.ui.controllers;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/account")
public class AccountController {

    @RequestMapping("/status")
    public String status(){
        return "Account Service is running";
    }
}
