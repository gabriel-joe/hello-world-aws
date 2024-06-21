package com.training.aws.model;

import java.time.LocalDate;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "users") //
public class UserEntity {
    
    @Id
    @Column(name = "username", nullable = false) 
    private String username;
    @Column(name = "birthday_date", nullable = false)
    private LocalDate dateOfBirth;

    public UserEntity() {
    }

    public UserEntity(String username, LocalDate dateOfBirth) {
        this.username = username;
        this.dateOfBirth = dateOfBirth;
    }

    public String getUsername(){
        return username;
    }

    public LocalDate getDateOfBirth(){
        return dateOfBirth; 
    }
}
