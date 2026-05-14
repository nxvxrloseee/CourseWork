package com.cw.rd.config;

import com.cw.rd.entity.*;
import com.cw.rd.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {

    private final RoleRepository roleRepository;
    private final UserRepository userRepository;
    private final TicketStatusRepository statusRepository;
    private final TicketCategoryRepository categoryRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) {
        seedRoles();
        seedStatuses();
        seedCategories();
        seedMaster();
    }

    private void seedRoles() {
        if (roleRepository.count() == 0) {
            roleRepository.saveAll(List.of(
                    Role.builder().name("CUSTOMER").build(),
                    Role.builder().name("MASTER").build()
            ));
            log.info("Роли созданы: CUSTOMER, MASTER");
        }
    }

    private void seedStatuses() {
        if (statusRepository.count() == 0) {
            List<String> statuses = List.of(
                    "Новая", "В работе", "Ожидает устройство",
                    "В ремонте", "Готово", "Завершена", "Отменена"
            );
            statuses.forEach(name ->
                    statusRepository.save(TicketStatus.builder().name(name).build())
            );
            log.info("Статусы заявок созданы: {}", statuses);
        }
    }

    private void seedCategories() {
        if (categoryRepository.count() == 0) {
            List<String> categories = List.of(
                    "Замена комплектующих", "Чистка и профилактика",
                    "Восстановление данных", "Диагностика",
                    "Ремонт после залития", "Другое"
            );
            categories.forEach(name ->
                    categoryRepository.save(TicketCategory.builder().name(name).build())
            );
            log.info("Категории заявок созданы: {}", categories);
        }
    }

    private void seedMaster() {
        if (userRepository.findByEmailAndIsDeletedFalse("master@repairdesk.ru").isEmpty()) {
            Role masterRole = roleRepository.findByName("MASTER")
                    .orElseThrow(() -> new RuntimeException("Роль MASTER не найдена"));

            User master = User.builder()
                    .surname("Мастеров")
                    .name("Мастер")
                    .patronymic("Мастерович")
                    .email("master@repairdesk.ru")
                    .passhash(passwordEncoder.encode("master123"))
                    .role(masterRole)
                    .build();

            userRepository.save(master);
            log.info("Мастер создан: master@repairdesk.ru / master123");
        }
    }
}
