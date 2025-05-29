package com.appsdeveloperblog.photoapp.api.users.ui.controllers;

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
