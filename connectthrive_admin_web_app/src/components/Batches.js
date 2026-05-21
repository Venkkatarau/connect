import { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  TextField,
  Button,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
  Avatar,
  Grid,
  Card,
  CardContent,
  CardActions,
  Stack,
  Container,
  Tooltip,
} from '@mui/material';
import {
  Add,
  CheckCircle,
  Close,
  Edit,
  Group,
  School,
  Send,
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';
import axios from 'axios';
import { toast, ToastContainer } from 'react-toastify';
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

const BatchCard = styled(Card)(({ theme }) => ({
  borderRadius: 12,
  transition: 'all 0.3s ease',
  '&:hover': {
    transform: 'translateY(-4px)',
    boxShadow: theme.shadows[6],
    borderColor: theme.palette.primary.main,
  },
}));

const Batches = () => {
  const [name, setBatchName] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);
  const [batches, setBatches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [currentBatch, setCurrentBatch] = useState(null);

  useEffect(() => {
    fetchBatches();
  }, []);

  const fetchBatches = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${process.env.REACT_APP_API_URL}/v1/admin/getAllBatches`);
      setBatches(response.data || []);
    } catch (error) {
      toast.error('Failed to fetch batches');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async () => {
    if (!name.trim()) {
      toast.error('Batch name cannot be empty');
      return;
    }

    setIsSubmitting(true);

    try {
      const endpoint = editMode && currentBatch
        ? `${process.env.REACT_APP_API_URL}/v1/admin/updateBatch/${currentBatch.id}`
        : `${process.env.REACT_APP_API_URL}/v1/admin/addBatch`;

      const method = editMode ? 'put' : 'post';

      const response = await axios[method](endpoint, { name });

      if (response.status === 200 || response.status === 201) {
        toast.success('Batch saved successfully!');
        setSubmitSuccess(true);
        setBatchName('');
        fetchBatches();
        setTimeout(() => {
          setSubmitSuccess(false);
          if (openDialog) setOpenDialog(false);
        }, 1500);
      } else {
        toast.error('Operation failed');
      }
    } catch (error) {
      toast.error(error.response?.data?.message || 'An error occurred');
    } finally {
      setIsSubmitting(false);
      setEditMode(false);
      setCurrentBatch(null);
    }
  };

  const handleEdit = (batch) => {
    setCurrentBatch(batch);
    setBatchName(batch.name);
    setEditMode(true);
    setOpenDialog(true);
  };

  const handleDialogClose = () => {
    setOpenDialog(false);
    setEditMode(false);
    setCurrentBatch(null);
    setBatchName('');
  };

  return (
    <Container maxWidth="lg">
      <StyledPaper elevation={3}>
        <Box display="flex" alignItems="center" gap={2} mb={3}>
          <School sx={{ fontSize: 40, color: '#3f51b5' }} />
          <Typography variant="h4" fontWeight="bold" sx={{ color: '#1a237e' }}>
            Add/Edit Batches
          </Typography>
        </Box>

        <Typography variant="body1" color="text.secondary" mb={4}>
          Manage your batches - create new ones or modify existing batches
        </Typography>

        {/* Add Batch Button */}
        <Box display="flex" justifyContent="flex-end" mb={4}>
          <StyledButton
            variant="contained"
            color="primary"
            startIcon={<Add />}
            onClick={() => setOpenDialog(true)}
          >
            Add New Batch
          </StyledButton>
        </Box>

        {/* Batches List */}
        {loading ? (
          <Box display="flex" justifyContent="center" py={6}>
            <CircularProgress size={60} color="primary" />
          </Box>
        ) : batches.length === 0 ? (
          <Box
            textAlign="center"
            py={8}
            border={1}
            borderColor="divider"
            borderRadius={12}
            sx={{ borderStyle: 'dashed' }}
          >
            <Group sx={{ fontSize: 60, color: 'text.disabled', mb: 2 }} />
            <Typography variant="h6" color="text.secondary" mb={2}>
              No batches found
            </Typography>
            <Typography variant="body1" color="text.secondary" mb={3}>
              Click "Add New Batch" to create your first batch
            </Typography>
            <StyledButton
              variant="outlined"
              color="primary"
              startIcon={<Add />}
              onClick={() => setOpenDialog(true)}
            >
              Add Batch
            </StyledButton>
          </Box>
        ) : (
          <Grid container spacing={3}>
            {batches.map((batch) => (
              <Grid item xs={12} sm={6} md={4} key={batch.id}>
                <BatchCard variant="outlined" sx={{ width: 346, mx: 'auto' }}>
                  <CardContent>
                    <Box display="flex" alignItems="center" gap={2} mb={2}>
                      <Avatar sx={{ bgcolor: 'primary.main' }}>
                        <Group />
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
                        {batch.name}
                      </Typography>
                    </Box>
                    <Stack direction="row" spacing={1} mt={2}>
                      <Typography variant="caption" color="text.secondary">
                        ID: {batch.id}
                      </Typography>
                    </Stack>
                  </CardContent>
                  <CardActions sx={{ justifyContent: 'flex-end' }}>
                    <Tooltip title="Edit">
                      <IconButton onClick={() => handleEdit(batch)}>
                        <Edit color="primary" />
                      </IconButton>
                    </Tooltip>
                  </CardActions>
                </BatchCard>
              </Grid>
            ))}
          </Grid>
        )}

        {/* Add/Edit Dialog */}
        <Dialog open={openDialog} onClose={handleDialogClose} maxWidth="sm" fullWidth>
          <DialogTitle>
            <Box display="flex" alignItems="center" justifyContent="space-between">
              <Typography variant="h6">
                {editMode ? 'Edit Batch' : 'Add New Batch'}
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
                label="Batch Name*"
                variant="outlined"
                value={name}
                onChange={(e) => setBatchName(e.target.value)}
                placeholder="Enter batch name (e.g., Batch A)"
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
              disabled={!name.trim() || isSubmitting}
              sx={{
                minWidth: 120,
                ...(submitSuccess && {
                  backgroundColor: '#4caf50',
                  '&:hover': { backgroundColor: '#388e3c' },
                }),
              }}
            >
              {isSubmitting ? 'Saving...' : submitSuccess ? 'Saved!' : 'Save'}
            </StyledButton>
          </DialogActions>
        </Dialog>
      </StyledPaper>
        <ToastContainer position="top-right" autoClose={3000} hideProgressBar />
    </Container>
  );
};

export default Batches;
