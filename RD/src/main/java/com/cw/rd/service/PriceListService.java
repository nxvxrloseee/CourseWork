package com.cw.rd.service;

import com.cw.rd.dto.service.*;
import com.cw.rd.entity.ServiceEntity;
import com.cw.rd.exception.ApiException;
import com.cw.rd.repository.ServiceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PriceListService {

    private final ServiceRepository serviceRepository;

    public List<ServiceResponse> getActiveServices() {
        return serviceRepository.findByIsActiveTrue().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public List<ServiceResponse> getAllServices() {
        return serviceRepository.findAll().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public ServiceResponse createService(ServiceRequest request) {
        if (serviceRepository.existsByNameIgnoreCase(request.getName())) {
            throw ApiException.badRequest("Услуга с таким наименованием уже существует");
        }
        ServiceEntity service = ServiceEntity.builder()
                .name(request.getName())
                .description(request.getDescription())
                .price(request.getPrice())
                .build();
        return toResponse(serviceRepository.save(service));
    }

    @Transactional
    public ServiceResponse updateService(Long id, ServiceRequest request) {
        ServiceEntity service = serviceRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Услуга не найдена"));

        if (serviceRepository.existsByNameIgnoreCaseAndIdNot(request.getName(), id)) {
            throw ApiException.badRequest("Услуга с таким наименованием уже существует");
        }

        service.setName(request.getName());
        service.setDescription(request.getDescription());
        service.setPrice(request.getPrice());

        return toResponse(serviceRepository.save(service));
    }

    @Transactional
    public void deactivateService(Long id) {
        ServiceEntity service = serviceRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Услуга не найдена"));
        service.setIsActive(false);
        serviceRepository.save(service);
    }

    @Transactional
    public void activateService(Long id) {
        ServiceEntity service = serviceRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Услуга не найдена"));
        service.setIsActive(true);
        serviceRepository.save(service);
    }

    private ServiceResponse toResponse(ServiceEntity s) {
        ServiceResponse r = new ServiceResponse();
        r.setId(s.getId());
        r.setName(s.getName());
        r.setDescription(s.getDescription());
        r.setPrice(s.getPrice());
        r.setIsActive(s.getIsActive());
        return r;
    }
}
