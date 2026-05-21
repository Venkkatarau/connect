import { useState, useEffect } from 'react';
import { 
  Box, 
  Typography, 
  Paper, 
  Grid, 
  FormControl, 
  InputLabel, 
  Select, 
  MenuItem, 
  Button, 
  CircularProgress,
  TextField,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  LinearProgress,
  Card,
  CardContent,
  CardActions,
  Avatar,
  Stack,
  Container,
  keyframes
} from '@mui/material';
import { 
  VideoLibrary, 
  CloudUpload, 
  AttachFile, 
  CheckCircle, 
  Close,
  Delete,
  Add,
  Send,
  Description,
  Videocam,
  Photo
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';

const VisuallyHiddenInput = styled('input')({
  clip: 'rect(0 0 0 0)',
  clipPath: 'inset(50%)',
  height: 1,
  overflow: 'hidden',
  position: 'absolute',
  bottom: 0,
  left: 0,
  whiteSpace: 'nowrap',
  width: 1,
});

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

const FixedWidthFormControl = styled(FormControl)({
  width: '100%',
  minWidth: 240,
  maxWidth: 280,
});

const checkmarkAnimation = keyframes`
  0% { transform: scale(0.8); opacity: 0; }
  50% { transform: scale(1.2); opacity: 0.8; }
  100% { transform: scale(1); opacity: 1; }
`;

const SuccessAnimation = styled(Box)({
  display: 'flex',
  flexDirection: 'column',
  alignItems: 'center',
  justifyContent: 'center',
  animation: `${checkmarkAnimation} 0.5s ease-in-out`,
});

const ProgressContainer = styled(Box)({
  width: '100%',
  maxWidth: 400,
  position: 'relative',
});

const ProgressText = styled(Typography)({
  position: 'absolute',
  top: '50%',
  left: '50%',
  transform: 'translate(-50%, -50%)',
  fontWeight: 'bold',
  color: '#fff',
});

const UploadVideo = () => {
   const [batches, setBatches] = useState([]);
  // const [courses, setCourses] = useState([]);
  const [modules, setModules] = useState([]);
  const [selectedBatch, setSelectedBatch] = useState('');
  const [selectedModule, setSelectedModule] = useState('');
 const [selectedConceptName, setselectedConceptName] = useState('');
  // const [selectedCourse, setSelectedCourse] = useState('');

  const [selectedVideoType, setSelectedVideoType] = useState('');
  const [videoFile, setVideoFile] = useState(null);
  const [thumbnailFile, setThumbnailFile] = useState(null);
  const [isUploading, setIsUploading] = useState(false);
  const [documents, setDocuments] = useState([]);
  const [openDocDialog, setOpenDocDialog] = useState(false);
  const [newDoc, setNewDoc] = useState({ file: null, caption: '' });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [showSuccess, setShowSuccess] = useState(false);
  const [isLoading, setIsLoading] = useState({
    batches: true,
    // courses: true,
    modules: true
  });

  const staticVideoType = [
  { id: '1', name: 'Setup Videos' },
  { id: '2', name: 'Transaction Videos' }
];


  useEffect(() => {
    // Fetch batches
    const fetchBatches = async () => {
      try {
        const response = await fetch(`${process.env.REACT_APP_API_URL}/v1/admin/getAllBatches`);
        const data = await response.json();
        setBatches(data);
      } catch (error) {
        console.error('Error fetching batches:', error);
      } finally {
        setIsLoading(prev => ({ ...prev, batches: false }));
      }
    };

    // Fetch courses
    // const fetchCourses = async () => {
    //   try {
    //     const response = await fetch(`${process.env.REACT_APP_API_URL}/v1/admin/getAllCourses`);
    //     const data = await response.json();
    //     setCourses(data);
    //   } catch (error) {
    //     console.error('Error fetching courses:', error);
    //   } finally {
    //     setIsLoading(prev => ({ ...prev, courses: false }));
    //   }
    // };

    // Fetch modules
    const fetchModules = async () => {
      try {
        const response = await fetch(`${process.env.REACT_APP_API_URL}/v2/admin/getAllModules`);
        const data = await response.json();
        setModules(data);
      } catch (error) {
        console.error('Error fetching modules:', error);
      } finally {
        setIsLoading(prev => ({ ...prev, modules: false }));
      }
    };

    fetchBatches();
   // fetchCourses();
    fetchModules();
  }, []);

  
  const handleThumbnailUpload = (event) => {
    const file = event.target.files[0];
    if (file) {
      setThumbnailFile(file);
    }
  };


  const handleVideoUpload = (event) => {
    const file = event.target.files[0];
    if (file) {
      setVideoFile(file);
    }
  };

  const handleAddDocument = () => {
    if (newDoc.file) {
      setDocuments([...documents, newDoc]);
      setNewDoc({ file: null, caption: '' });
      setOpenDocDialog(false);
    }
  };

  const handleRemoveDocument = (index) => {
    const updatedDocs = [...documents];
    updatedDocs.splice(index, 1);
    setDocuments(updatedDocs);
  };

  const handleRemoveVideo = () => {
    setVideoFile(null);
  };

    const handleRemoveThumbnail = () => {
    setThumbnailFile(null);
  };

  const handleSubmit = async () => {
    if (!videoFile || !thumbnailFile || !selectedModule || !selectedBatch || !selectedConceptName ) return;
    
    setIsSubmitting(true);
    setUploadProgress(0);
    setShowSuccess(false);
    
    try {
      const formData = new FormData();
      
      // Add video file
      formData.append('files', videoFile);
      formData.append('thubminalFile', thumbnailFile);
      // Add supporting documents
      documents.forEach(doc => {
        formData.append('files', doc.file);
      });
      
      // Add other form data
      formData.append('batchId', selectedBatch);
      formData.append('moduleId', selectedModule);
      formData.append('title', selectedConceptName);
      formData.append('videoType', selectedVideoType);

      // formData.append('courseId', selectedCourse);
      
      const xhr = new XMLHttpRequest();
      
      xhr.upload.addEventListener('progress', (event) => {
        if (event.lengthComputable) {
          const percentComplete = Math.round((event.loaded / event.total) * 90);
          setUploadProgress(percentComplete);
        }
      });
      
      xhr.onload = () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          setUploadProgress(100);
          setShowSuccess(true);
          
          setTimeout(() => {
            setSelectedBatch('');
            setSelectedModule('');
            setselectedConceptName('');
            // setSelectedCourse('');
            setSelectedVideoType('');
            setVideoFile(null);
            setThumbnailFile(null);
            setDocuments([]);
            setIsSubmitting(false);
            setUploadProgress(0);
            setShowSuccess(false);
          }, 2000);
        } else {
          throw new Error('Upload failed');
        }
      };
      
      xhr.onerror = () => {
        throw new Error('Upload failed');
      };
      
      xhr.open('POST', `${process.env.REACT_APP_API_URL}/v2/admin/upload/supportingDocuments`, true);
      xhr.send(formData);
      
    } catch (error) {
      console.error('Error uploading files:', error);
      setIsSubmitting(false);
      setUploadProgress(0);
    }
  };

  const showUploadSections = selectedModule;

  return (
    <Container maxWidth="lg">
      <StyledPaper elevation={3}>
        <Box display="flex" alignItems="center" gap={2} mb={3}>
          <VideoLibrary sx={{ fontSize: 40, color: '#3f51b5' }} />
          <Typography variant="h4" fontWeight="bold" sx={{ color: '#1a237e' }}>
            Upload Video Lecture
          </Typography>
        </Box>
        
        <Typography variant="body1" color="text.secondary" mb={4}>
          Upload and manage your lecture videos with supporting materials
        </Typography>
        
        {/* Selection Dropdowns */}
<Grid container spacing={3} justifyContent="center" mb={4}>
  <Grid item xs={12} sm={6} md={3}>
    <FixedWidthFormControl variant="outlined" fullWidth>
      <InputLabel id="batch-select-label">Select Batch*</InputLabel>
      <Select
        labelId="batch-select-label"
        value={selectedBatch}
        onChange={(e) => setSelectedBatch(e.target.value)}
        label="Select Batch"
        sx={{ borderRadius: 12 }}
        disabled={isLoading.batches}
      >
        {isLoading.batches ? (
          <MenuItem disabled>
            <CircularProgress size={24} />
          </MenuItem>
        ) : (
          batches.map((batch) => (
            <MenuItem key={batch.id} value={batch.id}>
              {batch.name}
            </MenuItem>
          ))
        )}
      </Select>
    </FixedWidthFormControl>
  </Grid>

  <Grid item xs={12} sm={6} md={3}>
    <FixedWidthFormControl variant="outlined" fullWidth>
      <InputLabel id="module-select-label">Select Module*</InputLabel>
      <Select
        labelId="module-select-label"
        value={selectedModule}
        onChange={(e) => setSelectedModule(e.target.value)}
        label="Select Module"
        sx={{ borderRadius: 12 }}
        disabled={isLoading.modules}
      >
        {isLoading.modules ? (
          <MenuItem disabled>
            <CircularProgress size={24} />
          </MenuItem>
        ) : (
          modules.map((module) => (
            <MenuItem key={module.id} value={module.id}>
              {module.name} ({module.tier})
            </MenuItem>
          ))
        )}
      </Select>
    </FixedWidthFormControl>
  </Grid>

  <Grid item xs={12} sm={6} md={3}>
    <FixedWidthFormControl variant="outlined" fullWidth>
      <InputLabel id="video-type-select-label">Select VideoType*</InputLabel>
      <Select
        labelId="video-type-select-label"
        value={selectedVideoType}
        onChange={(e) => setSelectedVideoType(e.target.value)}
        label="Select VideoType"
        sx={{ borderRadius: 12 }}
      >
        {staticVideoType.map((type) => (
          <MenuItem key={type.id} value={type.name}>
            {type.name}
          </MenuItem>
        ))}
      </Select>
    </FixedWidthFormControl>
  </Grid>

  <Grid item xs={12} md={3}>
    <TextField
      label="Concept Name*"
      variant="outlined"
      fullWidth
      value={selectedConceptName}
      onChange={(e) => setselectedConceptName(e.target.value)}
      placeholder="Enter the concept name"
      sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
    />
  </Grid>
</Grid>


        {/* Conditional Upload Sections */}
        {showUploadSections && (
          <>
<Box display="flex" justifyContent="center" mb={{ xs: 2, md: 4 }}>
  <Grid container spacing={3} mb={{ xs: 2, md: 4 }} justifyContent="center">
    {/* Video Upload Section */}
    <Grid item xs={12} sm={12} md={6} lg={4}>
      <Card variant="outlined" sx={{ borderRadius: 12, height: '100%' }}>
        <CardContent>
          <Box 
            display="flex" 
            alignItems="center" 
            justifyContent="space-between" 
            mb={3}
          >
            <Typography variant="h6" color="primary" noWrap>
              <Videocam sx={{ verticalAlign: 'middle', mr: 1 }} />
              Video File
            </Typography>
            <Typography variant="caption" color="error" noWrap>
              Required*
            </Typography>
          </Box>
          
          <Typography variant="body2" color="text.secondary" mb={3}>
            Upload a lecture video in MP4, MOV, or AVI format to share with learners.
          </Typography>
          
          {videoFile ? (
            <Card variant="outlined" sx={{ borderRadius: 8 }}>
              <CardContent sx={{ py: 2, '&:last-child': { pb: 2 } }}>
                <Box display="flex" alignItems="center" gap={2}>
                  <Avatar sx={{ bgcolor: 'primary.main' }}>
                    <Videocam />
                  </Avatar>
                  <Box flexGrow={1}>
                    <Typography 
                      variant="subtitle1"
                      noWrap
                      sx={{ 
                        maxWidth: { xs: '100%', sm: '330px' },
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap'
                      }}
                    >
                      {videoFile.name}
                    </Typography>
                    <Typography 
                      variant="body2" 
                      color="text.secondary"
                    >
                      {Math.round(videoFile.size / 1024 / 1024 * 100) / 100} MB
                    </Typography>
                  </Box>
                  <IconButton 
                    onClick={handleRemoveVideo}
                    color="error"
                  >
                    <Delete />
                  </IconButton>
                </Box>
              </CardContent>
            </Card>
          ) : (
            <Box 
              border={1} 
              borderColor="divider" 
              borderRadius={12} 
              p={3} 
              sx={{ 
                backgroundColor: 'rgba(63, 81, 181, 0.05)',
                borderStyle: 'dashed',
                textAlign: 'center',
                cursor: 'pointer',
                width: '100%',
                minHeight: 160,
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                alignItems: 'center',
              }}
            >
              <CloudUpload sx={{ fontSize: 48, color: 'primary.main' }} />
              <Typography variant="body1" gutterBottom>
                Drag and drop your video file here
              </Typography>
              <Typography variant="body2" color="text.secondary" mb={2}>
                Supported formats: MP4, MOV, AVI
              </Typography>
              
              <Button
                component="label"
                variant="contained"
                color="primary"
                startIcon={<CloudUpload />}
                sx={{ borderRadius: 12, width: { xs: '100%', sm: 'auto' } }}
              >
                Choose Video File
                <VisuallyHiddenInput 
                  type="file" 
                  accept="video/*" 
                  onChange={handleVideoUpload} 
                />
              </Button>
            </Box>
          )}
        </CardContent>
      </Card>
    </Grid>

    {/* Supporting Documents Section */}
    <Grid item xs={12} sm={12} md={6} lg={4}>
      <Card variant="outlined" sx={{ borderRadius: 12, height: '100%' }}>
        <CardContent>
          <Box 
            display="flex" 
            alignItems="center" 
            justifyContent="space-between" 
            mb={3}
          >
            <Typography variant="h6" color="primary" noWrap>
              <Description sx={{ verticalAlign: 'middle', mr: 1 }} />
              Supporting Documents
            </Typography>
            <Typography variant="caption" color="text.secondary" noWrap>
              Optional
            </Typography>
          </Box>
          
          <Typography variant="body2" color="text.secondary" mb={3}>
            Add supplementary materials like PDFs, slides to accompany your video.
          </Typography>

          {documents.length > 0 ? (
            <Stack spacing={2}>
              {documents.map((doc, index) => (
                <Card key={index} variant="outlined" sx={{ borderRadius: 8 }}>
                  <CardContent sx={{ py: 2, '&:last-child': { pb: 2 } }}>
                    <Box display="flex" alignItems="center" gap={2}>
                      <Avatar sx={{ bgcolor: 'primary.main' }}>
                        <AttachFile />
                      </Avatar>
                      <Box flexGrow={1}>
                        <Typography 
                          variant="subtitle1"
                          noWrap
                          sx={{ 
                            maxWidth: { xs: '100%', sm: '330px' },
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            whiteSpace: 'nowrap'
                          }}
                        >
                          {doc.file.name}
                        </Typography>
                        {doc.caption && (
                          <Typography 
                            variant="body2" 
                            color="text.secondary" 
                            noWrap
                            sx={{ 
                              maxWidth: { xs: '100%', sm: '330px' },
                              overflow: 'hidden', 
                              textOverflow: 'ellipsis', 
                              whiteSpace: 'nowrap' 
                            }}
                          >
                            {doc.caption}
                          </Typography>
                        )}
                      </Box>
                      <IconButton 
                        onClick={() => handleRemoveDocument(index)}
                        color="error"
                      >
                        <Delete />
                      </IconButton>
                    </Box>
                  </CardContent>
                </Card>
              ))}
            </Stack>
          ) : (
            <Box 
              textAlign="center" 
              py={4} 
              border={1} 
              borderColor="divider" 
              borderRadius={12}
              sx={{ borderStyle: 'dashed' }}
            >
              <Description sx={{ fontSize: 48, color: 'text.disabled', mb: 1 }} />
              <Typography variant="body1" color="text.secondary" mb={2}>
                No supporting documents added yet
              </Typography>
              <Button
                variant="outlined"
                color="primary"
                startIcon={<Add />}
                onClick={() => setOpenDocDialog(true)}
                sx={{ borderRadius: 12, width: { xs: '100%', sm: 'auto' } }}
              >
                Add Document
              </Button>
            </Box>
          )}
        </CardContent>
        <CardActions sx={{ justifyContent: 'flex-end', p: 2 }}>
          <Button
            variant="outlined"
            color="primary"
            startIcon={<Add />}
            onClick={() => setOpenDocDialog(true)}
            sx={{ borderRadius: 12, width: { xs: '100%', sm: 'auto' } }}
          >
            Add Another Document
          </Button>
        </CardActions>
      </Card>
    </Grid>

    {/* Upload Thumbnail */}
    <Grid item xs={12} sm={12} md={6} lg={4}>
      <Card variant="outlined" sx={{ borderRadius: 12, height: '100%' }}>
        <CardContent>
          <Box 
            display="flex" 
            alignItems="center" 
            justifyContent="space-between" 
            mb={3}
          >
            <Typography variant="h6" color="primary" noWrap>
              <Photo  sx={{ verticalAlign: 'middle', mr: 1 }} />
              Thumbnail File
            </Typography>
            <Typography variant="caption" color="error" noWrap>
              Required*
            </Typography>
          </Box>
          
          <Typography variant="body2" color="text.secondary" mb={3}>
            Upload a lecture thumbnail in PNG,JPEG,JPG format to share with learners.
          </Typography>
          
          {thumbnailFile ? (
            <Card variant="outlined" sx={{ borderRadius: 8 }}>
              <CardContent sx={{ py: 2, '&:last-child': { pb: 2 } }}>
                <Box display="flex" alignItems="center" gap={2}>
                  <Avatar sx={{ bgcolor: 'primary.main' }}>
                    <Photo />
                  </Avatar>
                  <Box flexGrow={1}>
                    <Typography 
                      variant="subtitle1"
                      noWrap
                      sx={{ 
                        maxWidth: { xs: '100%', sm: '330px' },
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap'
                      }}
                    >
                      {thumbnailFile.name}
                    </Typography>
                    <Typography 
                      variant="body2" 
                      color="text.secondary"
                    >
                      {Math.round(thumbnailFile.size / 1024 / 1024 * 100) / 100} MB
                    </Typography> 
                  </Box>
                  <IconButton 
                    onClick={handleRemoveThumbnail}
                    color="error"
                  >
                    <Delete />
                  </IconButton>
                </Box>
              </CardContent>
            </Card>
          ) : (
            <Box 
              border={1} 
              borderColor="divider" 
              borderRadius={12} 
              p={3} 
              sx={{ 
                backgroundColor: 'rgba(63, 81, 181, 0.05)',
                borderStyle: 'dashed',
                textAlign: 'center',
                cursor: 'pointer',
                width: '100%',
                minHeight: 160,
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                alignItems: 'center',
              }}
            >
              <CloudUpload sx={{ fontSize: 48, color: 'primary.main' }} />
              <Typography variant="body1" gutterBottom>
                Drag and drop your thumbnail file here
              </Typography>
              <Typography variant="body2" color="text.secondary" mb={2}>
                Supported formats: PNG
              </Typography>
              
              <Button
                component="label"
                variant="contained"
                color="primary"
                startIcon={<CloudUpload />}
                sx={{ borderRadius: 12, width: { xs: '100%', sm: 'auto' } }}
              >
                Choose thumbnail File
                <VisuallyHiddenInput 
                  type="file" 
                  accept="image/*" 
                  onChange={handleThumbnailUpload} 
                />
              </Button>
            </Box>
          )}
        </CardContent>
      </Card>
    </Grid>
  </Grid>
</Box>


            {/* Submit Button - Centered */}
            <Box display="flex" justifyContent="center" mt={4}>
              {isSubmitting ? (
                <ProgressContainer>
                  {showSuccess ? (
                    <SuccessAnimation>
                      <CheckCircle sx={{ fontSize: 48, color: '#4caf50', mb: 2 }} />
                      <Typography variant="h6" color="#4caf50" gutterBottom>
                        Lecture Saved Successfully!
                      </Typography>
                    </SuccessAnimation>
                  ) : (
                    <>
                      <LinearProgress 
                        variant="determinate" 
                        value={uploadProgress}
                        sx={{ 
                          height: 10, 
                          borderRadius: 5,
                          mb: 2,
                          backgroundColor: 'rgba(0, 0, 0, 0.1)',
                          '& .MuiLinearProgress-bar': {
                            backgroundColor: uploadProgress === 100 ? '#4caf50' : '#3f51b5',
                            transition: 'background-color 0.3s ease',
                          }
                        }} 
                      />
                      <ProgressText variant="body2">
                        {uploadProgress}%
                      </ProgressText>
                      <Typography variant="body2" textAlign="center" color="text.secondary">
                        {uploadProgress === 100 ? 'Finalizing...' : 'Uploading your lecture and materials...'}
                      </Typography>
                    </>
                  )}
                </ProgressContainer>
              ) : (
                <StyledButton
                  variant="contained"
                  color="primary"
                  size="large"
                  endIcon={<Send />}
                  onClick={handleSubmit}
                  disabled={!videoFile || !thumbnailFile}
                  sx={{ minWidth: 200 }}
                >
                  Submit Lecture
                </StyledButton>
              )}
            </Box>
          </>
        )}
        
        {/* Document Upload Dialog */}
        <Dialog open={openDocDialog} onClose={() => setOpenDocDialog(false)} maxWidth="sm" fullWidth>
          <DialogTitle>
            <Box display="flex" alignItems="center" justifyContent="space-between">
              <Typography variant="h6">Add Supporting Document</Typography>
              <IconButton onClick={() => setOpenDocDialog(false)}>
                <Close />
              </IconButton>
            </Box>
          </DialogTitle>
          <DialogContent>
            <Box mb={3}>
              <Button
                component="label"
                variant="outlined"
                color="primary"
                fullWidth
                startIcon={<AttachFile />}
                sx={{ borderRadius: 12, py: 2 }}
              >
                Select Document File
                <VisuallyHiddenInput 
                  type="file" 
                  onChange={(e) => setNewDoc({...newDoc, file: e.target.files[0]})} 
                />
              </Button>
              {newDoc.file && (
                <Box mt={1} display="flex" alignItems="center">
                  <AttachFile color="primary" sx={{ mr: 1 }} />
                  <Typography variant="body2">{newDoc.file.name}</Typography>
                </Box>
              )}
            </Box>
            
            <TextField
              label="Document Caption (Optional)"
              variant="outlined"
              fullWidth
              value={newDoc.caption}
              onChange={(e) => setNewDoc({...newDoc, caption: e.target.value})}
              placeholder="Enter a brief description of this document"
              sx={{ borderRadius: 12 }}
            />
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setOpenDocDialog(false)} sx={{ borderRadius: 12 }}>
              Cancel
            </Button>
            <Button 
              variant="contained" 
              onClick={handleAddDocument} 
              disabled={!newDoc.file}
              sx={{ borderRadius: 12 }}
            >
              Add Document
            </Button>
          </DialogActions>
        </Dialog>
      </StyledPaper>
    </Container>
  );
};

export default UploadVideo;