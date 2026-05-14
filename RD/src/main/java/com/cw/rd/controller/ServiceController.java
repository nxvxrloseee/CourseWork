package com.cw.rd.controller;

import com.cw.rd.dto.service.*;
import com.cw.rd.service.PriceListService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/services")
@RequiredArgsConstructor
public class ServiceController {

    private final PriceListService priceListService;

    @GetMapping
    public ResponseEntity<List<ServiceResponse>> getActiveServices() {
        return ResponseEntity.ok(priceListService.getActiveServices());
    }

    @GetMapping("/all")
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<List<ServiceResponse>> getAllServices() {
        return ResponseEntity.ok(priceListService.getAllServices());
    }

    @PostMapping
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<ServiceResponse> createService(@Valid @RequestBody ServiceRequest request) {
        return ResponseEntity.ok(priceListService.createService(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<ServiceResponse> updateService(@PathVariable Long id,
                                                          @Valid @RequestBody ServiceRequest request) {
        return ResponseEntity.ok(priceListService.updateService(id, request));
    }

    @PatchMapping("/{id}/deactivate")
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<Void> deactivate(@PathVariable Long id) {
        priceListService.deactivateService(id);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{id}/activate")
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<Void> activate(@PathVariable Long id) {
        priceListService.activateService(id);
        return ResponseEntity.ok().build();
    }
}
