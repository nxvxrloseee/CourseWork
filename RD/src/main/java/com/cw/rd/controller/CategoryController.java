package com.cw.rd.controller;

import com.cw.rd.entity.TicketCategory;
import com.cw.rd.repository.TicketCategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class CategoryController {

    private final TicketCategoryRepository categoryRepository;

    @GetMapping
    public ResponseEntity<List<TicketCategory>> getCategories() {
        return ResponseEntity.ok(categoryRepository.findAll());
    }
}
