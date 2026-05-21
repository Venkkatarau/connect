package com.connectthrive.connectthrive.user;

import com.connectthrive.connectthrive.user.model.CourseModuleResponse;
import com.connectthrive.connectthrive.user.serivce.ModuleQueryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/user/modules")
public class UserModuleController {

    @Autowired
    private ModuleQueryService queryService;

    /**
     * Get all the modules and paid or free with accessiablity
     * @param userId
     * @param courseId
     * @return
     */
    @GetMapping("/course/{courseId}")
    public List<CourseModuleResponse> getModulesForUser(@RequestParam Long userId, @PathVariable Long courseId) {
        return queryService.getModulesForUser(userId, courseId);
    }
}
