// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

contract TaskManager {
    enum Priority { Low, Medium, High }

    struct Task {
        string description;
        address assignedTo;
        bool completed;
        uint dueDate;
        Priority priority;
        uint createdAt;
    }

    mapping(uint => Task) private tasks;
    uint private taskCount;
    uint private showCount;

    address public owner;
    bool private paused = false;

    event TaskCreated(uint indexed taskId, string description, address assignedTo, uint dueDate, Priority priority);
    event TaskCompleted(uint indexed taskId);
    event TaskDeleted(uint indexed taskId);
    event TaskReassigned(uint indexed taskId, address indexed oldAssignee, address indexed newAssignee);
    event TaskUpdated(uint indexed taskId, string description, uint dueDate, Priority priority);
    event ContractPaused(address account);
    event ContractResumed(address account);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier validTaskId(uint _id) {
        require(_id <= taskCount && _id > 0, "Invalid task ID.");
        _;
    }

    modifier onlyAssignee(uint _id) {
        require(tasks[_id].assignedTo == msg.sender, "You're not assigned to this task.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function getTaskCount() public view returns (uint) {
        return showCount;
    }

    function createTask(string memory _description, uint _dueDate, Priority _priority) public whenNotPaused {
        taskCount++;
        showCount++;
        tasks[taskCount] = Task(_description, msg.sender, false, _dueDate, _priority, block.timestamp);
        emit TaskCreated(taskCount, _description, msg.sender, _dueDate, _priority);
    }

    function seeTasks(uint page, uint pageSize) public view returns (Task[] memory) {
        Task[] memory tasksToReturn = new Task[](showCount);
        uint validTaskCount = 0;

        for (uint i = 1; i <= taskCount; i++) {
            if (tasks[i].assignedTo == msg.sender) {
                tasksToReturn[validTaskCount] = tasks[i];
                validTaskCount++;
            }
        }

        // Sorting tasks by due date
        for (uint i = 0; i < validTaskCount - 1; i++) {
            for (uint j = 0; j < validTaskCount - i - 1; j++) {
                if (tasksToReturn[j].dueDate > tasksToReturn[j + 1].dueDate) {
                    Task memory tempTask = tasksToReturn[j];
                    tasksToReturn[j] = tasksToReturn[j + 1];
                    tasksToReturn[j + 1] = tempTask;
                }
            }
        }

        // Pagination
        uint startIndex = page * pageSize;
        uint endIndex = startIndex + pageSize;
        if (endIndex > validTaskCount) {
            endIndex = validTaskCount;
        }

        uint size = endIndex - startIndex;
        Task[] memory pagedTasks = new Task[](size);

        for (uint i = 0; i < size; i++) {
            pagedTasks[i] = tasksToReturn[startIndex + i];
        }

        return pagedTasks;
    }

    function getTask(uint _id) public view validTaskId(_id) returns (Task memory) {
        return tasks[_id];
    }

    function completeTask(uint _id) public validTaskId(_id) onlyAssignee(_id) whenNotPaused {
        Task storage task = tasks[_id];
        require(!task.completed, "Task is already completed.");
        task.completed = true;
        emit TaskCompleted(_id);
    }

    function deleteTask(uint _id) public validTaskId(_id) onlyAssignee(_id) whenNotPaused {
        delete tasks[_id];
        emit TaskDeleted(_id);
        showCount--;
    }

    function reassignTask(uint _id, address _newAssignee) public validTaskId(_id) onlyAssignee(_id) whenNotPaused {
        Task storage task = tasks[_id];
        address oldAssignee = task.assignedTo;
        task.assignedTo = _newAssignee;
        emit TaskReassigned(_id, oldAssignee, _newAssignee);
    }

    function updateTaskDescription(uint _id, string memory _newDescription) public validTaskId(_id) onlyAssignee(_id) whenNotPaused {
        Task storage task = tasks[_id];
        task.description = _newDescription;
        emit TaskUpdated(_id, _newDescription, task.dueDate, task.priority);
    }

    function updateTaskDueDate(uint _id, uint _newDueDate) public validTaskId(_id) onlyAssignee(_id) whenNotPaused {
        Task storage task = tasks[_id];
        task.dueDate = _newDueDate;
        emit TaskUpdated(_id, task.description, _newDueDate, task.priority);
    }

    function updateTaskPriority(uint _id, Priority _newPriority) public validTaskId(_id) onlyAssignee(_id) whenNotPaused {
        Task storage task = tasks[_id];
        task.priority = _newPriority;
        emit TaskUpdated(_id, task.description, task.dueDate, _newPriority);
    }

    function getTasksByPriority(Priority _priority) public view returns (uint[] memory) {
        uint[] memory result = new uint[](taskCount);
        uint count = 0;

        for (uint i = 1; i <= taskCount; i++) {
            if (tasks[i].priority == _priority) {
                result[count] = i;
                count++;
            }
        }

        uint[] memory finalResult = new uint[](count);
        for (uint j = 0; j < count; j++) {
            finalResult[j] = result[j];
        }

        return finalResult;
    }

    function getTasksByCompletion(bool _completed) public view returns (uint[] memory) {
        uint[] memory result = new uint[](taskCount);
        uint count = 0;

        for (uint i = 1; i <= taskCount; i++) {
            if (tasks[i].completed == _completed) {
                result[count] = i;
                count++;
            }
        }

        uint[] memory finalResult = new uint[](count);
        for (uint j = 0; j < count; j++) {
            finalResult[j] = result[j];
        }

        return finalResult;
    }

    function taskCountByAssignee(address _assignee) public view returns (uint) {
        uint count = 0;

        for (uint i = 1; i <= taskCount; i++) {
            if (tasks[i].assignedTo == _assignee) {
                count++;
            }
        }

        return count;
    }

    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }



    function resumeContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractResumed(msg.sender);
    }

    function isContractPaused() public view returns (bool) {
        return paused;
    }

    function ownerDeleteTask(uint _id) public validTaskId(_id) onlyOwner whenNotPaused {
        delete tasks[_id];
        emit TaskDeleted(_id);
        showCount--;
    }

    function getAllTasks() public view returns (
        uint[] memory taskIDs,
        string[] memory descriptions,
        address[] memory assignees,
        bool[] memory completions,
        uint[] memory dueDates,
        Priority[] memory priorities,
        uint[] memory creationDates
    ) {
        taskIDs = new uint[](taskCount);
        descriptions = new string[](taskCount);
        assignees = new address[](taskCount);
        completions = new bool[](taskCount);
        dueDates = new uint[](taskCount);
        priorities = new Priority[](taskCount);
        creationDates = new uint[](taskCount);

        for (uint i = 1; i <= taskCount; i++) {
            taskIDs[i-1] = i;
            descriptions[i-1] = tasks[i].description;
            assignees[i-1] = tasks[i].assignedTo;
            completions[i-1] = tasks[i].completed;
            dueDates[i-1] = tasks[i].dueDate;
            priorities[i-1] = tasks[i].priority;
            creationDates[i-1] = tasks[i].createdAt;
        }

        return (taskIDs, descriptions, assignees, completions, dueDates, priorities, creationDates);
    }
}

       
