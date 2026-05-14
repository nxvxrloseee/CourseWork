package com.cw.rd.service;

import com.cw.rd.dto.ticket.*;
import com.cw.rd.entity.*;
import com.cw.rd.exception.ApiException;
import com.cw.rd.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TicketManagementService {

    private final TicketRepository ticketRepository;
    private final TicketCategoryRepository categoryRepository;
    private final TicketStatusRepository statusRepository;
    private final TicketMediaRepository mediaRepository;
    private final TicketStatusHistoryRepository historyRepository;
    private final TicketServiceRepository ticketServiceRepository;
    private final ServiceRepository serviceRepository;
    private final UserRepository userRepository;
    private final UserService userService;
    private final FileService fileService;
    private final NotificationService notificationService;

    @Value("${business.hours.open:8}")
    private int businessOpen;
    @Value("${business.hours.close:22}")
    private int businessClose;

    private static final Map<String, Set<String>> ALLOWED_TRANSITIONS = Map.of(
            "В работе",           Set.of("Ожидает устройство", "Отменена"),
            "Ожидает устройство", Set.of("В ремонте", "Отменена"),
            "В ремонте",          Set.of("Готово", "Отменена"),
            "Готово",             Set.of("Завершена")
    );

    @Transactional
    public TicketResponse createTicket(Long customerId, CreateTicketRequest request, List<MultipartFile> files) {
        User customer = userService.getById(customerId);

        validateBusinessHours(request.getSelectedDatetime());

        TicketCategory category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> ApiException.notFound("Категория не найдена"));

        TicketStatus newStatus = statusRepository.findByName("Новая")
                .orElseThrow(() -> ApiException.notFound("Статус не найден"));

        Ticket ticket = Ticket.builder()
                .customer(customer)
                .category(category)
                .status(newStatus)
                .title(request.getTitle())
                .description(request.getDescription())
                .selectedDatetime(request.getSelectedDatetime())
                .build();

        ticket = ticketRepository.save(ticket);

        addStatusHistory(ticket, customer, newStatus, "Заявка создана");

        if (files != null) {
            for (MultipartFile file : files) {
                String path = fileService.uploadFile(file);
                TicketMedia media = TicketMedia.builder()
                        .ticket(ticket)
                        .pathToFile(path)
                        .build();
                mediaRepository.save(media);
            }
        }

        Ticket savedTicket = ticket;
        userRepository.findByRoleNameAndIsDeletedFalse("MASTER")
                .forEach(m -> notificationService.sendNotification(m.getId(),
                        "Поступила новая заявка на ремонт: " + savedTicket.getTitle(),
                        savedTicket.getId(), null));

        return toResponse(ticket);
    }

    public List<TicketResponse> getCustomerTickets(Long customerId, TicketFilterRequest filter) {
        Specification<Ticket> spec = Specification.where(
                (root, q, cb) -> cb.equal(root.get("customer").get("id"), customerId)
        );
        spec = applyFilters(spec, filter);

        return ticketRepository.findAll(spec, resolveSort(filter)).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public List<TicketResponse> getMasterTickets(TicketFilterRequest filter) {
        Specification<Ticket> spec = Specification.where(null);
        spec = applyFilters(spec, filter);

        return ticketRepository.findAll(spec, resolveSort(filter)).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    private Sort resolveSort(TicketFilterRequest filter) {
        if (filter == null || filter.getSort() == null) {
            return Sort.by(Sort.Direction.DESC, "createdAt");
        }
        return switch (filter.getSort()) {
            case "createdAtAsc"   -> Sort.by(Sort.Direction.ASC, "createdAt");
            case "idDesc"         -> Sort.by(Sort.Direction.DESC, "id");
            case "idAsc"          -> Sort.by(Sort.Direction.ASC, "id");
            case "scheduledDesc"  -> Sort.by(Sort.Direction.DESC, "selectedDatetime");
            case "scheduledAsc"   -> Sort.by(Sort.Direction.ASC, "selectedDatetime");
            case "statusAsc"      -> Sort.by(Sort.Direction.ASC, "status.name").and(Sort.by(Sort.Direction.DESC, "createdAt"));
            case "statusDesc"     -> Sort.by(Sort.Direction.DESC, "status.name").and(Sort.by(Sort.Direction.DESC, "createdAt"));
            default               -> Sort.by(Sort.Direction.DESC, "createdAt");
        };
    }

    public List<TicketResponse> getMasterHistory(Long masterId, TicketFilterRequest filter) {
        Specification<Ticket> spec = (root, q, cb) -> cb.equal(root.get("master").get("id"), masterId);
        spec = spec.and((root, q, cb) -> root.get("status").get("name").in("Завершена", "Отменена"));
        spec = applyFilters(spec, filter);
        return ticketRepository.findAll(spec, resolveSort(filter)).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public TicketResponse getTicketById(Long ticketId) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> ApiException.notFound("Заявка не найдена"));
        return toResponse(ticket);
    }

    @Transactional
    public TicketResponse takeTicket(Long ticketId, Long masterId) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> ApiException.notFound("Заявка не найдена"));

        if (!ticket.getStatus().getName().equals("Новая")) {
            throw ApiException.badRequest("Можно взять только заявку со статусом 'Новая'");
        }

        User master = userService.getById(masterId);
        TicketStatus inProgress = statusRepository.findByName("В работе")
                .orElseThrow(() -> ApiException.notFound("Статус не найден"));

        ticket.setMaster(master);
        ticket.setStatus(inProgress);
        ticketRepository.save(ticket);

        addStatusHistory(ticket, master, inProgress, "Заявка принята в работу");

        notificationService.sendNotification(ticket.getCustomer().getId(),
                "Ваша заявка «" + ticket.getTitle() + "» принята в работу мастером",
                ticket.getId(), null);

        return toResponse(ticket);
    }

    @Transactional
    public TicketResponse updateStatus(Long ticketId, Long userId, UpdateStatusRequest request) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> ApiException.notFound("Заявка не найдена"));

        if (ticket.getMaster() == null || !ticket.getMaster().getId().equals(userId)) {
            throw ApiException.forbidden("Вы не назначены на эту заявку");
        }

        String currentStatus = ticket.getStatus().getName();
        String targetStatus = request.getStatus();

        Set<String> allowed = ALLOWED_TRANSITIONS.getOrDefault(currentStatus, Set.of());
        if (!allowed.contains(targetStatus)) {
            throw ApiException.badRequest("Нельзя перевести заявку из «" + currentStatus + "» в «" + targetStatus + "»");
        }

        TicketStatus newStatus = statusRepository.findByName(targetStatus)
                .orElseThrow(() -> ApiException.notFound("Статус '" + targetStatus + "' не найден"));

        if ("Завершена".equals(newStatus.getName())
                && !ticketServiceRepository.findByTicketId(ticketId).isEmpty()
                && ticket.getPricesConfirmedAt() == null) {
            throw ApiException.badRequest("Заказчик ещё не подтвердил согласие с ценами на оказанные услуги");
        }

        User user = userService.getById(userId);

        ticket.setStatus(newStatus);
        ticketRepository.save(ticket);

        addStatusHistory(ticket, user, newStatus, request.getComment());

        String notificationText;
        if ("Готово".equals(newStatus.getName())) {
            notificationText = "Ваше устройство готово! Можете забрать его из мастерской (заявка «" + ticket.getTitle() + "»)";
        } else if ("Завершена".equals(newStatus.getName())) {
            notificationText = "Заявка «" + ticket.getTitle() + "» завершена. Оплата производится на стороне мастера (на месте) или переводом";
        } else {
            notificationText = "Статус вашей заявки «" + ticket.getTitle() + "» изменён на: " + newStatus.getName();
        }
        notificationService.sendNotification(ticket.getCustomer().getId(), notificationText,
                ticket.getId(), null);

        return toResponse(ticket);
    }

    @Transactional
    public TicketResponse cancelTicket(Long ticketId, Long customerId) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> ApiException.notFound("Заявка не найдена"));

        if (!ticket.getCustomer().getId().equals(customerId)) {
            throw ApiException.forbidden("Это не ваша заявка");
        }
        if (!ticket.getStatus().getName().equals("Новая")) {
            throw ApiException.badRequest("Отменить можно только заявку со статусом 'Новая'");
        }

        TicketStatus cancelled = statusRepository.findByName("Отменена")
                .orElseThrow(() -> ApiException.notFound("Статус не найден"));

        User customer = userService.getById(customerId);
        ticket.setStatus(cancelled);
        ticketRepository.save(ticket);

        addStatusHistory(ticket, customer, cancelled, "Заявка отменена заказчиком");

        if (ticket.getMaster() != null) {
            notificationService.sendNotification(ticket.getMaster().getId(),
                    "Заказчик отменил заявку «" + ticket.getTitle() + "»",
                    ticket.getId(), null);
        }

        return toResponse(ticket);
    }

    @Transactional
    public TicketResponse reschedule(Long ticketId, Long masterId, RescheduleRequest request) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> ApiException.notFound("Заявка не найдена"));

        if (ticket.getMaster() == null || !ticket.getMaster().getId().equals(masterId)) {
            throw ApiException.forbidden("Вы не назначены на эту заявку");
        }

        String status = ticket.getStatus().getName();
        if ("Готово".equals(status) || "Завершена".equals(status) || "Отменена".equals(status)) {
            throw ApiException.badRequest("Нельзя перенести заявку со статусом «" + status + "»");
        }

        validateBusinessHours(request.getNewDatetime());

        ticket.setSelectedDatetime(request.getNewDatetime());
        ticketRepository.save(ticket);

        User master = userService.getById(masterId);
        addStatusHistory(ticket, master, ticket.getStatus(),
                "Время передачи устройства перенесено на: " + request.getNewDatetime());

        notificationService.sendNotification(ticket.getCustomer().getId(),
                "Время передачи устройства перенесено на: " + request.getNewDatetime(),
                ticket.getId(), null);

        return toResponse(ticket);
    }

    @Transactional
    public TicketServiceResponse addServiceToTicket(Long ticketId, Long masterId, AddTicketServiceRequest request) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> ApiException.notFound("Заявка не найдена"));

        if (ticket.getMaster() == null || !ticket.getMaster().getId().equals(masterId)) {
            throw ApiException.forbidden("Вы не назначены на эту заявку");
        }

        String status = ticket.getStatus().getName();
        if ("Готово".equals(status) || "Завершена".equals(status) || "Отменена".equals(status)) {
            throw ApiException.badRequest("Нельзя добавлять услуги к заявке со статусом «" + status + "»");
        }

        ServiceEntity service = serviceRepository.findById(request.getServiceId())
                .orElseThrow(() -> ApiException.notFound("Услуга не найдена"));

        if (Boolean.FALSE.equals(service.getIsActive())) {
            throw ApiException.badRequest("Позиция прайс-листа неактивна");
        }

        if (ticketServiceRepository.existsByTicketIdAndServiceId(ticketId, service.getId())) {
            throw ApiException.badRequest("Эта услуга уже добавлена в заявку");
        }

        com.cw.rd.entity.TicketService ts = com.cw.rd.entity.TicketService.builder()
                .ticket(ticket)
                .service(service)
                .price(service.getPrice())
                .quantity(request.getQuantity())
                .build();

        ticketServiceRepository.save(ts);

        TicketServiceResponse r = new TicketServiceResponse();
        r.setId(ts.getId());
        r.setServiceId(service.getId());
        r.setServiceName(service.getName());
        r.setPrice(ts.getPrice());
        r.setQuantity(ts.getQuantity());
        r.setSubtotal(ts.getPrice().multiply(BigDecimal.valueOf(ts.getQuantity())));
        return r;
    }

    @Transactional
    public TicketServiceResponse updateTicketServiceQuantity(Long ticketServiceId, Long masterId, Integer quantity) {
        com.cw.rd.entity.TicketService ts = ticketServiceRepository.findById(ticketServiceId)
                .orElseThrow(() -> ApiException.notFound("Услуга заявки не найдена"));

        Ticket ticket = ts.getTicket();
        if (ticket.getMaster() == null || !ticket.getMaster().getId().equals(masterId)) {
            throw ApiException.forbidden("Вы не назначены на эту заявку");
        }

        String status = ticket.getStatus().getName();
        if ("Готово".equals(status) || "Завершена".equals(status) || "Отменена".equals(status)) {
            throw ApiException.badRequest("Нельзя изменять услуги заявки со статусом «" + status + "»");
        }

        ts.setQuantity(quantity);
        ticketServiceRepository.save(ts);

        TicketServiceResponse r = new TicketServiceResponse();
        r.setId(ts.getId());
        r.setServiceId(ts.getService().getId());
        r.setServiceName(ts.getService().getName());
        r.setPrice(ts.getPrice());
        r.setQuantity(ts.getQuantity());
        r.setSubtotal(ts.getPrice().multiply(BigDecimal.valueOf(ts.getQuantity())));
        return r;
    }

    @Transactional
    public void removeServiceFromTicket(Long ticketServiceId, Long masterId) {
        com.cw.rd.entity.TicketService ts = ticketServiceRepository.findById(ticketServiceId)
                .orElseThrow(() -> ApiException.notFound("Услуга заявки не найдена"));

        Ticket ticket = ts.getTicket();
        if (ticket.getMaster() == null || !ticket.getMaster().getId().equals(masterId)) {
            throw ApiException.forbidden("Вы не назначены на эту заявку");
        }

        String status = ticket.getStatus().getName();
        if ("Готово".equals(status) || "Завершена".equals(status) || "Отменена".equals(status)) {
            throw ApiException.badRequest("Нельзя изменять услуги заявки со статусом «" + status + "»");
        }

        ticketServiceRepository.delete(ts);
    }

    @Transactional
    public TicketResponse confirmPrices(Long ticketId, Long customerId) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> ApiException.notFound("Заявка не найдена"));

        if (!ticket.getCustomer().getId().equals(customerId)) {
            throw ApiException.forbidden("Это не ваша заявка");
        }
        if (ticket.getPricesConfirmedAt() != null) {
            throw ApiException.badRequest("Цены уже подтверждены");
        }
        String status = ticket.getStatus().getName();
        if ("Отменена".equals(status)) {
            throw ApiException.badRequest("Нельзя подтвердить цены отменённой заявки");
        }
        if (ticketServiceRepository.findByTicketId(ticketId).isEmpty()) {
            throw ApiException.badRequest("Услуги ещё не добавлены");
        }

        ticket.setPricesConfirmedAt(LocalDateTime.now());
        ticketRepository.save(ticket);

        User customer = userService.getById(customerId);
        addStatusHistory(ticket, customer, ticket.getStatus(), "Заказчик подтвердил согласие с ценами услуг");

        if (ticket.getMaster() != null) {
            notificationService.sendNotification(ticket.getMaster().getId(),
                    "Заказчик подтвердил согласие с ценами по заявке «" + ticket.getTitle() + "»",
                    ticket.getId(), null);
        }

        return toResponse(ticket);
    }

    public List<StatusHistoryResponse> getStatusHistory(Long ticketId) {
        return historyRepository.findByTicketIdOrderByUpdatedAtDesc(ticketId).stream()
                .map(h -> {
                    StatusHistoryResponse r = new StatusHistoryResponse();
                    r.setStatus(h.getStatus().getName());
                    r.setChangedBy(userService.getFullName(h.getUser()));
                    r.setDescription(h.getDescription());
                    r.setUpdatedAt(h.getUpdatedAt());
                    return r;
                }).collect(Collectors.toList());
    }

    private void validateBusinessHours(LocalDateTime dt) {
        if (dt == null) return;
        if (dt.isBefore(LocalDateTime.now())) {
            throw ApiException.badRequest("Дата передачи не может быть в прошлом");
        }
        int hour = dt.getHour();
        if (hour < businessOpen || hour >= businessClose) {
            throw ApiException.badRequest(
                    "Приём устройств доступен только с " + businessOpen + ":00 до " + businessClose + ":00");
        }
    }

    private void addStatusHistory(Ticket ticket, User user, TicketStatus status, String desc) {
        TicketStatusHistory history = TicketStatusHistory.builder()
                .ticket(ticket)
                .user(user)
                .status(status)
                .description(desc)
                .build();
        historyRepository.save(history);
    }

    private Specification<Ticket> applyFilters(Specification<Ticket> spec, TicketFilterRequest filter) {
        if (filter != null) {
            if (filter.getStatus() != null && !filter.getStatus().isBlank()) {
                spec = spec.and((root, q, cb) ->
                        cb.equal(root.get("status").get("name"), filter.getStatus()));
            }
            if (filter.getCategoryId() != null) {
                spec = spec.and((root, q, cb) ->
                        cb.equal(root.get("category").get("id"), filter.getCategoryId()));
            }
            if (filter.getSearch() != null && !filter.getSearch().isBlank()) {
                String pattern = "%" + filter.getSearch().toLowerCase() + "%";
                spec = spec.and((root, q, cb) -> {
                    if (q != null) q.distinct(true);
                    var customer = root.join("customer", jakarta.persistence.criteria.JoinType.LEFT);
                    var master = root.join("master", jakarta.persistence.criteria.JoinType.LEFT);
                    var category = root.join("category", jakarta.persistence.criteria.JoinType.LEFT);
                    var status = root.join("status", jakarta.persistence.criteria.JoinType.LEFT);
                    return cb.or(
                            cb.like(cb.lower(root.get("title")), pattern),
                            cb.like(cb.lower(root.get("description")), pattern),
                            cb.like(cb.lower(customer.get("name")), pattern),
                            cb.like(cb.lower(customer.get("surname")), pattern),
                            cb.like(cb.lower(customer.get("email")), pattern),
                            cb.like(cb.lower(master.get("name")), pattern),
                            cb.like(cb.lower(master.get("surname")), pattern),
                            cb.like(cb.lower(category.get("name")), pattern),
                            cb.like(cb.lower(status.get("name")), pattern),
                            cb.like(cb.function("to_char", String.class, root.get("id"), cb.literal("FM999999999")), pattern)
                    );
                });
            }
            if (Boolean.TRUE.equals(filter.getExcludeCompleted())) {
                spec = spec.and((root, q, cb) ->
                        cb.notEqual(root.get("status").get("name"), "Завершена"));
            }
        }
        return spec;
    }

    public TicketResponse toResponse(Ticket ticket) {
        TicketResponse r = new TicketResponse();
        r.setId(ticket.getId());
        r.setTitle(ticket.getTitle());
        r.setDescription(ticket.getDescription());
        r.setCategory(ticket.getCategory().getName());
        r.setStatus(ticket.getStatus().getName());
        r.setCustomerId(ticket.getCustomer().getId());
        r.setCustomerName(userService.getFullName(ticket.getCustomer()));

        if (ticket.getMaster() != null) {
            r.setMasterId(ticket.getMaster().getId());
            r.setMasterName(userService.getFullName(ticket.getMaster()));
        }

        r.setSelectedDatetime(ticket.getSelectedDatetime());
        r.setCreatedAt(ticket.getCreatedAt());
        r.setPricesConfirmedAt(ticket.getPricesConfirmedAt());

        List<String> urls = mediaRepository.findByTicketId(ticket.getId()).stream()
                .map(m -> fileService.getFileUrl(m.getPathToFile()))
                .collect(Collectors.toList());
        r.setMediaUrls(urls);

        List<com.cw.rd.entity.TicketService> services = ticketServiceRepository.findByTicketId(ticket.getId());
        List<TicketServiceResponse> serviceResponses = new ArrayList<>();
        BigDecimal total = BigDecimal.ZERO;
        for (com.cw.rd.entity.TicketService ts : services) {
            TicketServiceResponse sr = new TicketServiceResponse();
            sr.setId(ts.getId());
            sr.setServiceId(ts.getService().getId());
            sr.setServiceName(ts.getService().getName());
            sr.setPrice(ts.getPrice());
            sr.setQuantity(ts.getQuantity());
            BigDecimal sub = ts.getPrice().multiply(BigDecimal.valueOf(ts.getQuantity()));
            sr.setSubtotal(sub);
            total = total.add(sub);
            serviceResponses.add(sr);
        }
        r.setServices(serviceResponses);
        r.setTotalPrice(total);

        return r;
    }
}
