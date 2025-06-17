
package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class UserDetailResponse implements Serializable {

    private long id;
    private String email;
    private String firstname;
    private String lastname;
    private List<AlbumResponse> albums ;
}