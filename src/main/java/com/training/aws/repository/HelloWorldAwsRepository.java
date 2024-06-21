package com.training.aws.repository;

import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

import com.training.aws.model.UserEntity;

@Repository
public interface HelloWorldAwsRepository extends CrudRepository<UserEntity, String> {
    
}
