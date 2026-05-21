import { useState, useEffect } from 'react';
import {
  Box, Typography, Paper, TextField, Button, CircularProgress, Dialog, DialogTitle,
  DialogContent, DialogActions, IconButton, Avatar, Grid, Card, CardContent, CardActions,
  Container, Tooltip, Stack
} from '@mui/material';
import {
  Add, CheckCircle, Close, Edit, MenuBook, Send
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';
import axios from 'axios';
import { toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

const StyledPaper = styled(Paper)(({ theme }) => ({
  padding: theme.spacing(4),
  borderRadius: 16,
  background: 'linear-gradient(to bottom right, #f5f7fa, #e4e8f0)',
  boxShadow: '0 8px 32px rgba(0,0,0,0.1)',
}));

const StyledButton = styled(Button)(({ theme }) => ({
  borderRadius: 12,
  padding: '10px 24px',
  fontWeight: 600,
  textTransform: 'none',
  letterSpacing: 0.5,
  transition: 'all 0.3s ease',
  '&:hover': {
    transform: 'translateY(-2px)',
    boxShadow: theme.shadows[4],
  },
}));

const CourseCard = styled(Card)(({ theme }) => ({
  borderRadius: 12,
  transition: 'all 0.3s ease',
  width: 346,
  margin: '0 auto',
  '&:hover': {
    transform: 'translateY(-4px)',
    boxShadow: theme.shadows[6],
    borderColor: theme.palette.primary.main,
  },
}));

const Courses = () => {
  const [courseName, setCourseName] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentCourse, setCurrentCourse] = useState(null);

  useEffect(() => {
    fetchCourses();
  }, []);

  const fetchCourses = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${process.env.REACT_APP_API_URL}/v1/admin/getAllCourses`);
      setCourses(response.data || []);
      setLoading(false);
    } catch (error) {
      toast.error('Failed to fetch courses');
      setLoading(false);
    }
  };

  const handleSubmit = async () => {
    if (!courseName.trim()) {
      toast.error('Course name cannot be empty');
      return;
    }

    setIsSubmitting(true);
    try {
      let response;
      if (editMode && currentCourse) {
        response = await axios.put(
          `${process.env.REACT_APP_API_URL}/v1/admin/updateCourse/${currentCourse.courseId}`,
          { courseName }
        );
      } else {
        response = await axios.post(`${process.env.REACT_APP_API_URL}/v1/admin/addCourse`, { courseName });
      }

      toast.success(`${editMode ? 'Updated' : 'Added'} course successfully`);
      setSubmitSuccess(true);
      setCourseName('');
      fetchCourses();
      setTimeout(() => {
        setSubmitSuccess(false);
        if (openDialog) setOpenDialog(false);
      }, 1500);
    } catch (error) {
      toast.error(error.response?.data?.message || 'An error occurred');
    } finally {
      setIsSubmitting(false);
      setEditMode(false);
      setCurrentCourse(null);
    }
  };

  const handleEdit = (course) => {
    setCurrentCourse(course);
    setCourseName(course.courseName);
    setEditMode(true);
    setOpenDialog(true);
  };

  const handleDialogClose = () => {
    setOpenDialog(false);
    setEditMode(false);
    setCurrentCourse(null);
    setCourseName('');
  };

  return (
    <Container maxWidth="lg">
      <StyledPaper elevation={3}>
        <Box display="flex" alignItems="center" gap={2} mb={3}>
          <MenuBook sx={{ fontSize: 40, color: '#3f51b5' }} />
          <Typography variant="h4" fontWeight="bold" sx={{ color: '#1a237e' }}>
            Add/Edit Courses
          </Typography>
        </Box>

        <Typography variant="body1" color="text.secondary" mb={4}>
          Manage your courses - create new ones or modify existing courses
        </Typography>

        <Box display="flex" justifyContent="flex-end" mb={4}>
          <StyledButton
            variant="contained"
            color="primary"
            startIcon={<Add />}
            onClick={() => setOpenDialog(true)}
          >
            Add New Course
          </StyledButton>
        </Box>

        {loading ? (
          <Box display="flex" justifyContent="center" py={6}>
            <CircularProgress size={60} color="primary" />
          </Box>
        ) : courses.length === 0 ? (
          <Box
            textAlign="center"
            py={8}
            border={1}
            borderColor="divider"
            borderRadius={12}
            sx={{ borderStyle: 'dashed' }}
          >
            <MenuBook sx={{ fontSize: 60, color: 'text.disabled', mb: 2 }} />
            <Typography variant="h6" color="text.secondary" mb={2}>
              No courses found
            </Typography>
            <Typography variant="body1" color="text.secondary" mb={3}>
              Click "Add New Course" to create your first course
            </Typography>
            <StyledButton
              variant="outlined"
              color="primary"
              startIcon={<Add />}
              onClick={() => setOpenDialog(true)}
            >
              Add Course
            </StyledButton>
          </Box>
        ) : (
          <Grid container spacing={3}>
            {courses.map((course) => (
              <Grid item xs={12} sm={6} md={4} key={course.courseId}>
                <CourseCard variant="outlined">
                  <CardContent>
                    <Box display="flex" alignItems="center" gap={2} mb={2}>
                      <Avatar sx={{ bgcolor: 'primary.main' }}>
                        <MenuBook />
                      </Avatar>
                      <Typography
                        variant="h6"
                        sx={{
                          flex: 1,
                          minWidth: 0,
                          overflow: 'hidden',
                          whiteSpace: 'nowrap',
                          textOverflow: 'ellipsis',
                        }}
                      >
                        {course.courseName}
                      </Typography>
                    </Box>
                    <Stack direction="row" spacing={1} mt={2}>
                      <Typography variant="caption" color="text.secondary">
                        ID: {course.courseId}
                      </Typography>
                    </Stack>
                  </CardContent>
                  <CardActions sx={{ justifyContent: 'flex-end' }}>
                    <Tooltip title="Edit">
                      <IconButton onClick={() => handleEdit(course)}>
                        <Edit color="primary" />
                      </IconButton>
                    </Tooltip>
                  </CardActions>
                </CourseCard>
              </Grid>
            ))}
          </Grid>
        )}

        <Dialog open={openDialog} onClose={handleDialogClose} maxWidth="sm" fullWidth>
          <DialogTitle>
            <Box display="flex" alignItems="center" justifyContent="space-between">
              <Typography variant="h6">
                {editMode ? 'Edit Course' : 'Add New Course'}
              </Typography>
              <IconButton onClick={handleDialogClose}>
                <Close />
              </IconButton>
            </Box>
          </DialogTitle>
          <DialogContent>
            <Box my={3}>
              <TextField
                fullWidth
                label="Course Name*"
                variant="outlined"
                value={courseName}
                onChange={(e) => setCourseName(e.target.value)}
                placeholder="Enter course name (e.g., Java, Python)"
              />
            </Box>
          </DialogContent>
          <DialogActions>
            <Button onClick={handleDialogClose} sx={{ borderRadius: 12 }}>
              Cancel
            </Button>
            <StyledButton
              variant="contained"
              color="primary"
              endIcon={
                isSubmitting ? (
                  <CircularProgress size={24} color="inherit" />
                ) : submitSuccess ? (
                  <CheckCircle />
                ) : (
                  <Send />
                )
              }
              onClick={handleSubmit}
              disabled={!courseName.trim() || isSubmitting}
              sx={{
                minWidth: 120,
                ...(submitSuccess && {
                  backgroundColor: '#4caf50',
                  '&:hover': { backgroundColor: '#388e3c' }
                })
              }}
            >
              {isSubmitting ? 'Saving...' : submitSuccess ? 'Saved!' : 'Save'}
            </StyledButton>
          </DialogActions>
        </Dialog>
      </StyledPaper>
    </Container>
  );
};

export default Courses;
