package com.appsdeveloperblog.photoapp.api.album;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
@EnableDiscoveryClient
@EnableFeignClients // Ajouter cette annotation
public class PhotoAppApiAlbumApplication {

	public static void main(String[] args) {
		SpringApplication.run(PhotoAppApiAlbumApplication.class, args);
	}

}
