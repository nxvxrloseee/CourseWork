package com.cw.rd.repository;

import com.cw.rd.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmailAndIsDeletedFalse(String email);
    boolean existsByEmail(String email);
    List<User> findByRoleNameAndIsDeletedFalse(String roleName);
}
