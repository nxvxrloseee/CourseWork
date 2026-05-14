package com.cw.rd.controller;

import com.cw.rd.dto.ticket.*;
import com.cw.rd.service.TicketManagementService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/tickets")
@RequiredArgsConstructor
public class TicketController {

    private final TicketManagementService ticketService;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<TicketResponse> createTicket(
            Authentication auth,
            @Valid @RequestPart("ticket") CreateTicketRequest request,
            @RequestPart(value = "files", required = false) List<MultipartFile> files) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ticketService.createTicket(userId, request, files));
    }

    @GetMapping("/my")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<List<TicketResponse>> getMyTickets(
            Authentication auth,
            @ModelAttribute TicketFilterRequest filter) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ticketService.getCustomerTickets(userId, filter));
    }

    @GetMapping
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<List<TicketResponse>> getAllTickets(@ModelAttribute TicketFilterRequest filter) {
        return ResponseEntity.ok(ticketService.getMasterTickets(filter));
    }

    @GetMapping("/history")
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<List<TicketResponse>> getMasterHistory(
            Authentication auth,
            @ModelAttribute TicketFilterRequest filter) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ticketService.getMasterHistory(userId, filter));
    }

    @GetMapping("/{id}")
    public ResponseEntity<TicketResponse> getTicket(@PathVariable Long id) {
        return ResponseEntity.ok(ticketService.getTicketById(id));
    }

    @GetMapping("/{id}/history")
    public ResponseEntity<List<StatusHistoryResponse>> getStatusHistory(@PathVariable Long id) {
        return ResponseEntity.ok(ticketService.getStatusHistory(id));
    }

    @PostMapping("/{id}/take")
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<TicketResponse> takeTicket(@PathVariable Long id, Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ticketService.takeTicket(id, userId));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<TicketResponse> updateStatus(
            @PathVariable Long id,
            Authentication auth,
            @Valid @RequestBody UpdateStatusRequest request) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ticketService.updateStatus(id, userId, request));
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<TicketResponse> cancelTicket(@PathVariable Long id, Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ticketService.cancelTicket(id, userId));
    }

    @PostMapping("/{id}/confirm-prices")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<TicketResponse> confirmPrices(@PathVariable Long id, Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ticketService.confirmPrices(id, userId));
    }

    @PatchMapping("/{id}/reschedule")
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<TicketResponse> reschedule(
            @PathVariable Long id,
            Authentication auth,
            @Valid @RequestBody RescheduleRequest request) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ticketService.reschedule(id, userId, request));
    }

    @PostMapping("/{id}/services")
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<TicketServiceResponse> addService(
            @PathVariable Long id,
            Authentication auth,
            @Valid @RequestBody AddTicketServiceRequest request) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ticketService.addServiceToTicket(id, userId, request));
    }

    @DeleteMapping("/{ticketId}/services/{serviceId}")
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<Void> removeService(
            @PathVariable Long ticketId,
            @PathVariable Long serviceId,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        ticketService.removeServiceFromTicket(serviceId, userId);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{ticketId}/services/{ticketServiceId}")
    @PreAuthorize("hasRole('MASTER')")
    public ResponseEntity<TicketServiceResponse> updateServiceQuantity(
            @PathVariable Long ticketId,
            @PathVariable Long ticketServiceId,
            Authentication auth,
            @Valid @RequestBody UpdateTicketServiceRequest request) {
        Long userId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ticketService.updateTicketServiceQuantity(ticketServiceId, userId, request.getQuantity()));
    }
}
