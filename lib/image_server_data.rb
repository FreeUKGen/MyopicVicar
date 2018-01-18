module ImageServerData

  DIFFICULTY = {
    'c'     => 'Complicated Forms', 
    'd'     => 'Damaged', 
    'l'     => 'Learning', 
    'p17'   => 'Post 1700 modern freehand', 
    'p15s'  => 'Post 1530 freehand Secretary',  
    'p15l'  => 'Post 1530 freehand Latin', 
    'p15c'  => 'Post 1530 freehand Latin Chancery', 
    's'     => 'Straight Forward Forms'
  }
  
  STATUS = {
    'u'   => 'Unallocated', 
    'ar'  => 'Allocation Requested', 
    'a'   => 'Allocated', 
    'bt'  => 'Being Transcribed', 
    'ts'  => 'Transcription Submitted', 
    't'   => 'Transcribed', 
    'br'  => 'Being Reviewed', 
    'rs'  => 'Review Submitted', 
    'r'   => 'Reviewed', 
    'cs'  => 'Completion Submitted', 
    'c'   => 'Complete', 
    'e'   => 'Error'
  }

  STATUS_ARRAY = ['u', 'ar', 'a', 'bt', 'ts', 't', 'br', 'rs', 'r', 'cs', 'c', 'e']

end
